defmodule FarmbotCeleryScript.Compiler.Move do
  # alias FarmbotCeleryScript.Compiler
  alias FarmbotCeleryScript.SysCalls

  def move(%{body: body}, _env) do
    calculate_movement(body)
  end

  def calculate_movement(body) do
    result = list_of_ops(body)
    IO.inspect(result, label: "=== result")
    result
  end

  def list_of_ops(body) do
    mapper = &FarmbotCeleryScript.Compiler.Move.mapper/1
    reducer = &FarmbotCeleryScript.Compiler.Move.reducer/2
    list = initial_state() ++ Enum.map(body, mapper)
    result = Enum.reduce(list, %{}, reducer)
    IO.inspect(result, label: "=== result")
    result
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
    [
      {"x", :=, SysCalls.get_current_x()},
      {"y", :=, SysCalls.get_current_y()},
      {"z", :=, SysCalls.get_current_z()},
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
