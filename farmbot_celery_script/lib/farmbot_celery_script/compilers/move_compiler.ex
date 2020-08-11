defmodule FarmbotCeleryScript.Compiler.Move do
  alias FarmbotCeleryScript.SysCalls

  def move(%{body: body}, _env) do
    quote location: :keep do
      node_body = unquote(body)
      mod = unquote(__MODULE__)
      mod.perform_movement(node_body, better_params)
    end
  end

  # === "private" API starts here:
  def perform_movement(body, better_params) do
    extract_variables(body, better_params)
    |> calculate_movement_needs()
    |> do_perform_movement()
  end

  def extract_variables(body, better_params) do
    Enum.map(body, fn
      %{args: %{axis_operand: %{args: %{label: label}, kind: :identifier}}} = x ->
        new_operand = Map.fetch!(better_params, label)
        old_args = Map.fetch!(x, :args)
        new_args = Map.put(old_args, :axis_operand, new_operand)
        Map.put(x, :args, new_args)

      x ->
        x
    end)
  end

  def do_perform_movement(%{"safe_z" => true} = needs) do
    needs
    |> retract_z()
    |> move_xy()
    |> extend_z()
  end

  def do_perform_movement(%{"safe_z" => false} = needs) do
    move_xyz(needs)
  end

  def retract_z(needs) do
    SysCalls.move_absolute(
      needs["current_x"],
      needs["current_y"],
      needs["z"],
      needs["speed_x"],
      needs["speed_y"],
      needs["speed_z"]
    )

    needs
  end

  def move_xy(needs) do
    SysCalls.move_absolute(
      needs["x"],
      needs["y"],
      needs["current_z"],
      needs["speed_x"],
      needs["speed_y"],
      needs["speed_z"]
    )

    needs
  end

  def move_xyz(needs) do
    SysCalls.move_absolute(
      needs["x"],
      needs["y"],
      needs["z"],
      needs["speed_x"],
      needs["speed_y"],
      needs["speed_z"]
    )

    needs
  end

  def extend_z(needs) do
    SysCalls.move_absolute(
      needs["current_x"],
      needs["current_y"],
      needs["z"],
      needs["speed_x"],
      needs["speed_y"],
      needs["speed_z"]
    )

    needs
  end

  def calculate_movement_needs(body) do
    mapper = &FarmbotCeleryScript.Compiler.Move.mapper/1
    reducer = &FarmbotCeleryScript.Compiler.Move.reducer/2
    list = initial_state() ++ Enum.map(body, mapper)
    Enum.reduce(list, %{}, reducer)
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

    # identifier lua numeric point random special_value
    axis_operand = a[:axis_operand]

    # STRING: "x"|"y"|"z"|"all"
    axis = a[:axis]

    if axis == "all" do
      raise "Not permitted"
    end

    case k do
      :axis_overwrite ->
        {axis, :=, to_number(axis, axis_operand)}

      :axis_addition ->
        {axis, :+, to_number(axis, axis_operand)}

      :speed_overwrite ->
        {"speed_#{axis}", :=, to_number(axis, speed_setting)}

      :safe_z ->
        {"safe_z", :=, true}
    end
  end

  def initial_state do
    %{x: x, y: y, z: z} = current_location()

    [
      {"current_x", :=, x},
      {"current_y", :=, y},
      {"current_z", :=, z},
      {"x", :=, x},
      {"y", :=, y},
      {"z", :=, z},
      {"speed_x", :=, 100},
      {"speed_y", :=, 100},
      {"speed_z", :=, 100},
      {"safe_z", :=, false}
    ]
  end

  defp current_location do
    %{
      x: SysCalls.get_current_x(),
      y: SysCalls.get_current_y(),
      z: SysCalls.get_current_z()
    }
  end

  defp to_number(_axis, %{args: %{number: num}, kind: :numeric}), do: num

  defp to_number(_axis, %{args: %{lua: lua}, kind: :lua}) do
    result = SysCalls.raw_lua_eval(lua)

    case result do
      {:ok, data} ->
        if is_number(data) do
          data
        else
          lua_fail(data, lua)
        end

      data ->
        lua_fail(data, lua)
    end
  end

  defp to_number(_axis, %{args: %{variance: v}, kind: :random}) do
    Enum.random((-1 * v)..v)
  end

  defp to_number(axis, %{kind: :coordinate} = coord) do
    get_coord(coord[:args], axis)
  end

  defp to_number(axis, %{resource_id: id, resource_type: t}) do
    point = FarmbotCeleryScript.SysCalls.point(t, id)
    get_coord(point, axis)
  end

  # TODO: Add `safe_height` entry to FBOS Config
  defp to_number(_axis, %{
         args: %{label: "safe_height"},
         kind: :special_value
       }),
       do: 0

  defp to_number(axis, %{
         args: %{label: "current_location"},
         kind: :special_value
       }) do
    get_coord(current_location(), axis)
  end

  # ???
  defp to_number(axis, %{x: _, y: _, z: _} = coord) do
    get_coord(coord, axis)
  end

  defp to_number(_axis, arg) do
    raise "Can't handle numeric conversion for " <> inspect(arg)
  end

  defp lua_fail(result, lua) do
    raise "Unexpected Lua return: #{inspect(result)} #{lua}"
  end

  defp get_coord(%{x: _, y: _, z: _} = coord, axis) when is_atom(axis) do
    get_coord(coord, axis)
  end

  defp get_coord(%{x: _, y: _, z: _} = coord, axis) do
    get_coord(coord, String.to_atom(axis))
  end
end
