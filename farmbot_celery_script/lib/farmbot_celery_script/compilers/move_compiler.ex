defmodule FarmbotCeleryScript.Compiler.Move do
  # alias FarmbotCeleryScript.Compiler
  alias FarmbotCeleryScript.SysCalls

  def move(%{body: body}, _env) do
    quote location: :keep do
      node_body = unquote(body)
      mod = unquote(__MODULE__)
      mod.perform_movement(node_body)
    end
  end

  # === "private" API starts here:
  def perform_movement(body) do
    do_perform_movement(calculate_movement_needs(body))
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
        {axis, :=, to_number(axis_operand)}

      :axis_addition ->
        {axis, :+, to_number(axis_operand)}

      :speed_overwrite ->
        {"speed_#{axis}", :=, to_number(speed_setting)}

      :safe_z ->
        {"safe_z", :=, true}
    end
  end

  def initial_state do
    x = SysCalls.get_current_x()
    y = SysCalls.get_current_y()
    z = SysCalls.get_current_z()

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

  defp to_number(%{args: %{number: num}, kind: :numeric}), do: num

  defp to_number(%{args: %{lua: lua}, kind: :lua}) do
    IO.puts("TODO: Lua execution for real")
    {result, _} = Code.eval_string(lua)
    result
  end

  defp to_number(%{args: %{variance: v}, kind: :random}) do
    Enum.random((-1 * v)..v)
  end

  defp to_number(arg) do
    raise "Can't handle numeric conversion for " <> inspect(arg)
  end
end
