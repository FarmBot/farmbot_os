defmodule Farmbot.CeleryScript.AST.Node.SendMessage do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  allow_args [:message, :message_type]

  def execute(%{message: m, message_type: type}, channels, env) do
    env = mutate_env(env)
    {:ok, env, channels} = do_reduce(channels, env, [])
    msg = String.replace(m, "{{", "<%=")
    |> String.replace("}}", "%>")
    |> EEx.eval_string(fetch_bindings())

    case type do
      "debug" ->
        Logger.debug 2, msg, channels: channels
        {:ok, env}
      "info" ->
        Logger.info 2, msg, channels: channels
        {:ok, env}
      "busy" ->
        Logger.busy 2, msg, channels: channels
        {:ok, env}
      "success" ->
        Logger.success 2, msg, channels: channels
        {:ok, env}
      "warn" ->
        Logger.warn 2, msg, channels: channels
        {:ok, env}
      "error" ->
        Logger.error 2, msg, channels: channels
        {:ok, env}
      other ->
        {:error, "unknown type: #{other}", env}
    end
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

  defp do_reduce([%{args: %{channel_name: channel}} | rest], env, acc) do
    do_reduce(rest, env, [channel | acc])
  end

  defp do_reduce([], env, acc), do: {:ok, env, acc}
end
