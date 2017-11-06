defmodule Farmbot.CeleryScript.AST.Node.SendMessage do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:message, :message_type]

  def execute(%{message: m, message_type: type}, _, env) do
    env = mutate_env(env)
    String.replace(m, "{{", "<%=")
    |> String.replace("}}", "%>")
    |> EEx.eval_string(fetch_bindings())
    |> Logger.info([message_type: type])
    {:ok, env}
  rescue
    e in CompileError ->
      {:error, Exception.message(e), env}
    e -> reraise(e, System.stacktrace())
  end

  defp fetch_bindings do
    bot_state = Farmbot.BotState.force_state_push()
    pins = Enum.map(bot_state.pins, fn({pin, %{value: value}}) -> {pin, value} end)
    location = Enum.map(bot_state.location_data.position, fn({axis, val}) -> {axis, val} end)
    pins ++ location
  end
end
