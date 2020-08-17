defmodule FarmbotCeleryScript.Compiler.Move do
  alias FarmbotCeleryScript.SysCalls
  @safe_height 0

  # Temporary workaround because NervesHub appears to be broke
  # at the moment.
  def install_update(url) do
    path = "/tmp/fw#{trunc(:random.uniform() * 10000)}.fw"

    {:ok, :saved_to_file} =
      :httpc.request(:get, {to_charlist(url), []}, [], stream: to_charlist(path))

    args = [
      "-a",
      "-i",
      path,
      "-d",
      "/dev/mmcblk0",
      "-t",
      "upgrade"
    ]

    {_, 0} = System.cmd("fwup", args)
    FarmbotCeleryScript.SysCalls.reboot()
  end

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

  def do_perform_movement(%{safe_z: true} = needs) do
    needs |> retract_z() |> move_xy() |> extend_z()
  end

  def do_perform_movement(%{safe_z: false} = n) do
    move_abs("do_perform_movement", n)
  end

  def retract_z(needs) do
    a = %{x: cx(), y: cy(), z: @safe_height}
    b = Map.merge(needs, a)
    move_abs("retract_z", b)
    needs
  end

  def move_xy(needs) do
    move_abs("move_xy", Map.merge(needs, %{z: cz()}))
    needs
  end

  def extend_z(needs) do
    move_abs("extend_z", Map.merge(needs, %{x: cx(), y: cy()}))
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
    axis = String.to_atom(a[:axis] || "none")

    if axis == "all" do
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
      {:safe_z, :=, false}
    ]
  end

  defp to_number(_axis, %{args: %{number: num}, kind: :numeric}) do
    num
  end

  defp to_number(_axis, %{args: %{lua: lua}, kind: :lua}) do
    result = SysCalls.raw_lua_eval(lua)

    case result do
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

  defp to_number(_axis, %{args: %{variance: v}, kind: :random}) do
    Enum.random((-1 * v)..v)
  end

  defp to_number(axis, %{kind: :coordinate} = coord) do
    get_coord(coord[:args], axis)
  end

  # EXHIBIT A
  defp to_number(axis, %{resource_id: id, resource_type: t}) do
    point = FarmbotCeleryScript.SysCalls.point(t, id)
    get_coord(point, axis)
  end

  # EXHIBIT B
  defp to_number(axis, %{args: %{pointer_id: id, pointer_type: t}}) do
    to_number(axis, %{resource_id: id, resource_type: t})
  end

  defp to_number(_axis, %{
         args: %{label: "safe_height"},
         kind: :special_value
       }),
       do: @safe_height

  defp to_number(axis, %{
         args: %{label: "current_location"},
         kind: :special_value
       }) do
    get_coord(%{x: cx(), y: cy(), z: cz()}, axis)
  end

  defp to_number(axis, %{x: _, y: _, z: _} = coord) do
    get_coord(coord, axis)
  end

  defp to_number(_axis, arg) do
    raise "Can't handle numeric conversion for " <> inspect(arg)
  end

  defp lua_fail(result, lua) do
    raise "Unexpected Lua return: #{inspect(result)} #{lua}"
  end

  defp get_coord(%{x: _, y: _, z: _} = coord, axis) do
    Map.fetch!(coord, axis)
  end

  defp move_abs(
         caller,
         %{x: x, y: y, z: z, speed_x: sx, speed_y: sy, speed_z: sz} = k
       ) do
    SysCalls.log("Move_abs (#{caller}): " <> inspect(k), true)
    # If we wanted to add a "forceful" mode, we could do it here.
    :ok = SysCalls.move_absolute(x, y, z, sx, sy, sz)
    k
  end

  defp move_abs(caller, other) do
    raise "Possible string/atom issue? (#{inspect(caller)}, #{inspect(other)})"
  end

  def cx, do: SysCalls.get_current_x()
  def cy, do: SysCalls.get_current_y()
  def cz, do: SysCalls.get_current_z()
end
