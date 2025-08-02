defmodule FarmbotOS.Celery.Compiler.Move do
  alias FarmbotOS.Celery.SysCallGlue
  alias FarmbotOS.Celery.SpecialValue
  alias FarmbotOS.Celery.Compiler.Scope

  def move(%{body: body}, cs_scope) do
    quote location: :keep do
      # move_compiler.ex
      unquote(__MODULE__).perform_movement(unquote(body), unquote(cs_scope))
    end
  end

  # === "private" API starts here:
  def perform_movement(body, cs_scope) do
    extract_variables(body, cs_scope)
    |> preprocess_lua(cs_scope)
    |> calculate_movement_needs()
    |> do_perform_movement()
  end

  # If the user provides Lua, we need to evaluate the Lua and
  # transform it to a `numeric` node type.
  def preprocess_lua(body, cs_scope) do
    Enum.map(body, fn
      %{args: %{speed_setting: %{args: %{lua: lua}}}} = p ->
        data = convert_lua_to_number(lua, cs_scope)
        new_setting = %{kind: :numeric, args: %{number: data}}
        %{p | args: %{speed_setting: new_setting}}

      %{args: %{lua: lua}} = p ->
        data = convert_lua_to_number(lua, cs_scope)
        %{p | args: %{kind: :numeric, args: %{number: data}}}

      %{args: %{axis_operand: %{args: %{lua: lua}}}} = p ->
        data = convert_lua_to_number(lua, cs_scope)
        new_operand = %{args: %{number: data}, kind: :numeric}
        %{p | args: %{p.args | axis_operand: new_operand}}

      # Non-Lua nodes just pass through.
      item ->
        item
    end)
  end

  def extract_variables(body, cs_scope) do
    Enum.map(body, fn
      %{args: %{axis_operand: %{args: %{label: label}, kind: :identifier}}} = x ->
        {:ok, new_operand} = Scope.fetch!(cs_scope, label)
        old_args = Map.fetch!(x, :args)
        new_args = Map.put(old_args, :axis_operand, new_operand)
        Map.put(x, :args, new_args)

      x ->
        x
    end)
  end

  defp z_group?(group), do: String.downcase(group) |> String.contains?("z")

  defp reorder_axis_groups(groups, :first) do
    cond do
      z_group?(hd(groups)) -> groups
      z_group?(List.last(groups)) -> Enum.reverse(groups)
      true -> promote_first_matching(groups)
    end
  end

  defp reorder_axis_groups(groups, :last),
    do: reorder_axis_groups(groups, :first) |> Enum.reverse()

  defp promote_first_matching(groups) do
    case Enum.find_index(groups, &z_group?/1) do
      nil ->
        groups

      idx ->
        {before, [match | rest]} = Enum.split(groups, idx)
        [match | before ++ rest]
    end
  end

  defp normalize_axis_group(group) do
    group
    |> String.graphemes()
    |> Enum.sort()
    |> Enum.join()
  end

  defp perform_axis_group(group, needs) do
    case normalize_axis_group(group) do
      "x" -> move_x(needs)
      "y" -> move_y(needs)
      "z" -> extend_z(needs)
      "xy" -> move_xy(needs)
      "xz" -> move_xz(needs)
      "yz" -> move_yz(needs)
      "xyz" -> move_abs(needs)
    end
  end

  def do_perform_movement(%{safe_z: true} = needs) do
    needs |> retract_z() |> move_xy() |> extend_z()
  end

  def do_perform_movement(
        %{axis_order: %{grouping: order_str, route: route}} = needs
      ) do
    target_z = Map.get(needs, :z)
    current_z = cz()
    groups = String.split(order_str, ",", trim: true)

    route_mode =
      case String.downcase(route) do
        "high" -> :optimize_up
        "low" -> :optimize_down
        "in_order" -> :preserve
      end

    reordered_groups =
      case {route_mode, target_z, current_z} do
        {:preserve, _, _} ->
          groups

        {mode, t, c} ->
          direction =
            case {mode, abs(t) < abs(c)} do
              {:optimize_up, true} -> :first
              {:optimize_up, false} -> :last
              {:optimize_down, true} -> :last
              {:optimize_down, false} -> :first
            end

          reorder_axis_groups(groups, direction)
      end

    Enum.reduce(reordered_groups, needs, fn group, acc ->
      perform_axis_group(group, acc)
    end)
  end

  def retract_z(needs) do
    a = %{x: cx(), y: cy(), z: SpecialValue.safe_height()}
    b = Map.merge(needs, a)
    move_abs(b)
    needs
  end

  def move_xy(needs) do
    move_abs(Map.merge(needs, %{z: cz()}))
    needs
  end

  def move_xz(needs) do
    move_abs(Map.merge(needs, %{y: cy()}))
    needs
  end

  def move_yz(needs) do
    move_abs(Map.merge(needs, %{x: cx()}))
    needs
  end

  def move_x(needs) do
    move_abs(Map.merge(needs, %{y: cy(), z: cz()}))
    needs
  end

  def move_y(needs) do
    move_abs(Map.merge(needs, %{x: cx(), z: cz()}))
    needs
  end

  def extend_z(needs) do
    move_abs(Map.merge(needs, %{x: cx(), y: cy()}))
    needs
  end

  # Creates a list of operations that will look something like
  # this:
  #
  # [
  #   {:x, :=, 0.0},
  #   {:y, :=, 0.0},
  #   {:speed_x, :=, 100},
  #   {:speed_y, :=, 100},
  #   {:y, :=, 80.0},
  #   {:x, :=, 0.0},
  #   {:y, :=, 3},
  #   {:y, :+, 2.0},
  #   {:speed_y, :=, 50},
  #   {:z, :=, 0.0},
  #   {:speed_z, :=, 100},
  #   {:safe_z, :=, false},
  #   {:z, :=, 0.0},
  #   {:z, :=, {:skip, :soil_height}},
  #   {:z, :+, -21},
  #   {:axis_order, :=, %{grouping: "xyz", route: "in_order"}}
  #   {:safe_z, :=, true}
  # ]
  #
  # These operations are fed into a reducer function that creates
  # a proper x/y/z/speed map that we can use for move_abs calls.
  #
  # A few things to keep in mind:
  #  * ORDER MATTERS: Each operation will change the shape of
  #                   the final output map. This means we can't
  #                   arbitrarily sort operations for readability,
  #                   uniqueness, etc..
  #  * Z AXIS LAST:   The Z axis operations are special. They
  #                   require all X/Y operations to be completed
  #                   first. This is because `soil_height`
  #                   interpolation relies on X/Y data to calculate
  #                   Z height. If X/Y values were to change, it
  #                   would invalidate the Z height calculation.
  def create_list_of_operations(body) do
    mapper = &FarmbotOS.Celery.Compiler.Move.mapper/1
    # Move X/Y operations to the front of the list and move
    # Z operations to the back, but DO NOT SORT!:
    {xy, z} =
      (initial_state() ++ Enum.map(body, mapper))
      |> Enum.split_with(fn
        {:safe_z, _, _} ->
          false

        {:speed_z, _, _} ->
          false

        {:z, _, _} ->
          false

        {:axis_order, _, _} ->
          false

        _ ->
          true
      end)

    xy ++ z
  end

  def calculate_movement_needs(body) do
    body
    |> add_defaults()
    |> create_list_of_operations()
    |> Enum.reduce(%{}, &reducer/2)
  end

  def reducer({_, _, {:skip, :soil_height}}, state) do
    z =
      state
      |> Map.take([:x, :y])
      |> SpecialValue.soil_height()

    Map.put(state, :z, z)
  end

  def reducer({key, :+, value}, state) do
    Map.put(state, key, state[key] + value)
  end

  def reducer({key, :=, value}, state) do
    Map.put(state, key, value)
  end

  def mapper(%{kind: k, args: a}) do
    # lua, numeric
    speed_setting = a[:speed_setting]

    # identifier lua numeric point random special_value tool
    axis_operand = a[:axis_operand]

    # STRING: "x"|"y"|"z"|"all"
    axis = String.to_atom(a[:axis] || "none")

    if axis == :all do
      raise "Not permitted"
    end

    case k do
      :axis_overwrite ->
        {axis, :=, to_number(axis, axis_operand)}

      :axis_addition ->
        {axis, :+, to_number(axis, axis_operand)}

      :speed_overwrite ->
        next_speed = String.to_atom("speed_#{axis}")
        {next_speed, :=, to_number(axis, speed_setting)}

      :axis_order ->
        {:axis_order, :=, %{grouping: a[:grouping], route: a[:route]}}

      :safe_z ->
        {:safe_z, :=, true}
    end
  end

  def initial_state do
    [
      {:x, :=, cx()},
      {:y, :=, cy()},
      {:z, :=, cz()},
      {:speed_x, :=, 100},
      {:speed_y, :=, 100},
      {:speed_z, :=, 100},
      {:axis_order, :=, %{grouping: "xyz", route: "in_order"}},
      {:safe_z, :=, false}
    ]
  end

  defp default_axis_order() do
    FarmbotOS.Asset.fbos_config(:default_axis_order)
  end

  defp add_defaults(body) do
    if Enum.any?(body, fn %{kind: k} -> k == :axis_order end) do
      body
    else
      default_order = default_axis_order()

      case default_order do
        "safe_z" ->
          body ++ [%{kind: :safe_z, args: %{}}]

        _ ->
          [grouping, route] = String.split(default_order, ";")

          body ++
            [%{kind: :axis_order, args: %{grouping: grouping, route: route}}]
      end
    end
  end

  def to_number(_axis, %{args: %{variance: v}, kind: :random}) do
    Enum.random((-1 * v)..v)
  end

  def to_number(axis, %{kind: :coordinate, args: coord}) do
    to_number(axis, coord)
  end

  def to_number(_axis, %{args: %{number: num}, kind: :numeric}) do
    num
  end

  # This usually happens when `identifier`s are converted to
  # real values
  def to_number(axis, %{resource_id: id, resource_type: t}) do
    Map.fetch!(SysCallGlue.point(t, id), axis)
  end

  def to_number(axis, %{args: %{pointer_id: id, pointer_type: t}}) do
    Map.fetch!(SysCallGlue.point(t, id), axis)
  end

  def to_number(_, %{args: %{label: "safe_height"}, kind: :special_value}) do
    SpecialValue.safe_height()
  end

  def to_number(_, %{args: %{label: "soil_height"}, kind: :special_value}) do
    # As the `kind` label suggests, `soil_height` is a special
    # value. It cannot be treated as a number. We must skip
    # this value when performing axis math.
    {:skip, :soil_height}
  end

  def to_number(axis, %{
        args: %{label: "current_location"},
        kind: :special_value
      }) do
    to_number(axis, %{x: cx(), y: cy(), z: cz()})
  end

  def to_number(axis, %{x: _, y: _, z: _} = coord) do
    Map.fetch!(coord, axis)
  end

  def to_number(axis, %{kind: :tool, args: %{tool_id: id}}) do
    tool = FarmbotOS.Celery.SysCallGlue.get_toolslot_for_tool(id)
    to_number(axis, tool)
  end

  def to_number(_axis, arg) do
    raise "Can't handle numeric conversion for " <> inspect(arg)
  end

  def move_abs(%{x: x, y: y, z: z, speed_x: sx, speed_y: sy, speed_z: sz} = k) do
    x_str = FarmbotOS.Celery.FormatUtil.format_float(x)
    y_str = FarmbotOS.Celery.FormatUtil.format_float(y)
    z_str = FarmbotOS.Celery.FormatUtil.format_float(z)
    msg = "Moving to (#{x_str}, #{y_str}, #{z_str})"

    FarmbotOS.Celery.SysCallGlue.log(msg, true)
    :ok = SysCallGlue.move_absolute(x, y, z, sx, sy, sz)
    k
  end

  def cx, do: SysCallGlue.get_current_x()
  def cy, do: SysCallGlue.get_current_y()
  def cz, do: SysCallGlue.get_current_z()

  def convert_lua_to_number(lua, cs_scope) do
    case FarmbotOS.Celery.Compiler.Lua.do_lua(lua, cs_scope) do
      {:ok, [data]} ->
        if is_number(data) do
          data
        else
          lua_fail(data, lua)
        end

      data ->
        lua_fail(data, lua)
    end
  end

  def lua_fail(result, lua) do
    raise "Expected Lua to return number, got #{inspect(result)}. #{inspect(lua)}"
  end
end
