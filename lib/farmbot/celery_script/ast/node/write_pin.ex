defmodule Farmbot.CeleryScript.AST.Node.WritePin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  use Farmbot.Logger
  alias Farmbot.CeleryScript.AST
  alias AST.Node.NamedPin
  alias Farmbot.Asset
  alias Asset.Peripheral

  allow_args [:pin_number, :pin_value, :pin_mode]

  def execute(%{pin_number: %AST{kind: NamedPin} = named_pin, pin_mode: mode, pin_value: val}, _body, env) do
    env = mutate_env(env)
    id = named_pin.args.pin_id
    type = named_pin.args.pin_type
    case fetch_resource(type, id) do
      %Peripheral{pin: num, label: name} -> do_write(env, num, mode, val, name)
      {:error, reason} -> {:error, reason, env}
    end
  end

  def execute(%{pin_mode: mode, pin_value: value, pin_number: num}, [], env) do
    env = mutate_env(env)
    case fetch_resource(nil, num) do
      %Peripheral{pin: num, label: name} ->
        do_write(env, num, mode, value, name)
      {:ok, ^num} -> do_write(env, num, mode, value, "Pin #{num}")
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp do_write(env, num, mode, value, msg) do
    env = mutate_env(env)
    case Farmbot.Firmware.write_pin(num, mode, value) do
      :ok ->
        log_success(msg, num, mode, value)
        {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end

  defp log_success(msg, _num, :digital, 1) do
    Logger.success 1, "#{msg} turned ON"
  end

  defp log_success(msg, _num, :digital, 0) do
    Logger.success 1, "#{msg} turned OFF"
  end

  defp log_success(msg, _num, _, val) do
    Logger.success 1, "#{msg} set to #{val} (analog)"
  end

  defp fetch_resource(Peripheral, id) do
    case Asset.get_peripheral_by_id(id) do
      %Peripheral{} = per -> per
      nil -> {:error, "Could not find pin by id: #{id}"}
    end
  end

  defp fetch_resource(nil, number) do
    try_lookup_peripheral(number) || {:ok, number}
  end

  defp try_lookup_peripheral(number) do
    Asset.get_peripheral_by_number(number)
  end
end
