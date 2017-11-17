defmodule Farmbot.CeleryScript.AST.Node.SendMessage do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  allow_args [:message, :message_type]

  def execute(%{message: m, message_type: type}, channels, env) do
    env = mutate_env(env)
    {:ok, env, channels} = do_reduce(channels, env, [])
    bindings = fetch_bindings(env)
    case sanatize(m) do
      {:ok, sanatized} ->
        msg = EEx.eval_string(sanatized, bindings)
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
      {:error, reason} -> {:error, reason, env}
    end

  rescue
    e in CompileError ->
      case Exception.message(e) do
        "nofile:1: undefined function " <> undef ->
          Logger.error 2, "Unknown variable: #{undef}"
          {:error, :unknown_variable, env}
        _ ->
          {:error, Exception.message(e), env}
      end
    e -> reraise(e, System.stacktrace())
  end

  defp sanatize(message, global_acc \\ "", local_acc \\ "", mode \\ :global)

  defp sanatize(<<>>, global, _local, _mode), do: {:ok, global}

  defp sanatize(<<"{{", rest :: binary >>, acc, _local, _mode) do
    sanatize(rest, acc <> "<%=", "", :local)
  end

  defp sanatize(<<"}}", rest ::binary >>, global_acc, local_acc, _) do
    case sanatize_local(local_acc) do
      {:ok, sanatized} ->
        sanatize(rest, global_acc <> sanatized <> "%>", "", :global)
      {:error, reason} -> {:error, reason}
    end
  end

  defp sanatize(<<char, rest :: binary>>, global, _local, :global) do
    sanatize(rest, global <> <<char>>, "", :global)
  end

  defp sanatize(<<char, rest :: binary>>, global, local, :local) do
    sanatize(rest, global, local <> <<char>>, :local)
  end

  defp sanatize_local(local) do
    cond do
      String.contains?(local, "(") or String.contains?(local, ")") ->
        {:error, "templates may not contain special characters: `(` or `)`"}
      String.contains?(local, ".") ->
        {:error, "templates may not contain special character: `.`"}
      String.contains?(local, ":") ->
        {:error, "templates may not contain special character: `.`"}
      String.contains?(local, "[") or String.contains?(local, "]") ->
        {:error, "templates may not contain special characters: `[` or `]`"}
      String.contains?(local, "\"") or String.contains?(local, "\'") or String.contains?(local, "\`") ->
        {:error, "templates may not sub strings."}
      true -> {:ok, local}
    end
  end

  defp fetch_bindings(env) do
    bot_state = Farmbot.BotState.force_state_push()
    pins = Enum.map(bot_state.pins, fn({pin, %{value: value}}) -> {:"pin#{pin}", value} end)
    location = Enum.map(bot_state.location_data.position, fn({axis, val}) -> {axis, val} end)
    env.vars ++ pins ++ location
  end

  defp do_reduce([%{args: %{channel_name: channel}} | rest], env, acc) do
    do_reduce(rest, env, [channel | acc])
  end

  defp do_reduce([], env, acc), do: {:ok, env, acc}
end
