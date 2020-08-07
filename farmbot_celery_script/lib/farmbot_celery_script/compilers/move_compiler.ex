defmodule FarmbotCeleryScript.Compiler.Move do
  # alias FarmbotCeleryScript.Compiler
  alias FarmbotCeleryScript.SysCalls

  def move(%{body: body}, _env) do
    starting_point = %{
      x: SysCalls.get_current_x(),
      y: SysCalls.get_current_y(),
      z: SysCalls.get_current_z(),
      speed_x: 100,
      speed_y: 100,
      speed_z: 100,
      safe_z: false
    }

    reducer = fn %{kind: k, args: a}, state ->
      # lua, numeric
      speed_setting = a[:speed_setting]

      # identifier lua numeric point random special_value
      axis_operand = a[:axis_operand]

      # STRING: "x"|"y"|"z"|"all"
      axis = a[:axis]

      case k do
        :axis_overwrite ->
          # Has a :axis, :axis_operand
          IO.inspect({axis, to_number(axis_operand)},
            label: "=== TODO axis_overwrite"
          )

          state

        :axis_addition ->
          # Has a :axis, :axis_operand
          IO.inspect({axis, to_number(axis_operand)},
            label: "=== TODO axis_addition"
          )

          state

        :speed_overwrite ->
          # Has a :speed_setting, :axis
          IO.inspect({axis, to_number(speed_setting)},
            label: "=== TODO speed_overwrite"
          )

          state

        :safe_z ->
          state
      end
    end

    Enum.reduce(body, starting_point, reducer)
  end

  defp to_number(%{args: %{number: num}, kind: :numeric}), do: num

  defp to_number(%{args: %{lua: lua}, kind: :lua}) do
    IO.puts("TODO: Lua execution for real")
    {result, _} = Code.eval_string(lua)
    result
  end

  defp to_number(%{args: %{variance: v}, kind: :random}) do
    IO.puts("TODO: Lua execution for real")
    v
  end

  defp to_number(arg) do
    raise "Can't handle numeric conversion for " <> inspect(arg)
  end
end
