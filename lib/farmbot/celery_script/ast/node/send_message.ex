defmodule Farmbot.CeleryScript.AST.Node.SendMessage do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  allow_args [:message, :message_type]

  # credo:disable-for-this-file

  def execute(%{message: m, message_type: type}, channels, env) do
    env = mutate_env(env)
    {:ok, env, channels} = do_reduce_channels(channels, env, [])
    bindings = fetch_bindings(env)
    msg = :bbmustache.render(m, bindings)
    case type do
      "debug" ->
        Logger.debug 1, msg, channels: channels
        {:ok, env}
      "info" ->
        Logger.info 1, msg, channels: channels
        {:ok, env}
      "busy" ->
        Logger.busy 1, msg, channels: channels
        {:ok, env}
      "success" ->
        Logger.success 1, msg, channels: channels
        {:ok, env}
      "warn" ->
        Logger.warn 1, msg, channels: channels
        {:ok, env}
      "warning" ->
        Logger.warn 1, msg, channels: channels
        {:ok, env}
      "error" ->
        Logger.error 1, msg, channels: channels
        {:ok, env}
      other ->
        {:error, "unknown type: #{other}", env}
    end
  end

  defp fetch_bindings(env) do
    bot_state = Farmbot.BotState.force_state_push()
    pins = 0..69
      |> Enum.map(fn(pin_num) -> {pin_num, ~c(pin#{pin_num}), "Unknown"} end)
      |> Enum.map(fn({pin_num, key, value}) ->
        case bot_state.pins[pin_num] do
          %{value: value} when is_number(value) -> {key, value}
          _ -> {key, value}
        end
      end)
      |> Map.new()

    location = Map.new(bot_state.location_data.position, fn({axis, val}) -> {~c(#{axis}), val || "Unknown"} end)

    vars = Map.new(env.vars, fn({key, val}) -> {~c(#{key}), val} end)

    Map.merge(%{}, %{})
    |> Map.merge(vars)
    |> Map.merge(pins)
    |> Map.merge(location)
    |> IO.inspect(label: "ENV")
  end

  defp do_reduce_channels([%{args: %{channel_name: channel}} | rest], env, acc) do
    do_reduce_channels(rest, env, [channel | acc])
  end

  defp do_reduce_channels([], env, acc), do: {:ok, env, acc}
end
