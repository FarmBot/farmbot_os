defmodule Farmbot.CeleryScript.AST.Node.ReadPin do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  alias Farmbot.CeleryScript.AST
  alias AST.Node.NamedPin
  allow_args [:pin_number, :label, :pin_mode]
  use Farmbot.Logger
  alias Farmbot.Repo.Context
  alias Farmbot.Repo.Peripheral

  def execute(%{pin_number: %AST{kind: NamedPin} = named_pin, pin_mode: mode, label: label}, body, env) do
    env = mutate_env(env)
    id = named_pin.args.pin_id
    case Context.get_peripheral(id) do
      %Peripheral{pin: number} ->
        execute(%{pin_number: number, pin_mode: mode, label: label}, body, env)
      nil -> {:error, "Could not find pin by id: #{id}", env}
    end
  end

  def execute(%{pin_number: pin_num, pin_mode: mode, label: label}, _, env) when is_number(pin_num) do
    env = mutate_env(env)
    case Farmbot.Firmware.read_pin(pin_num, mode) do
      :ok ->
        case Farmbot.BotState.get_pin_value(pin_num) do
          {:ok, val} ->
            Logger.info 2, "Read pin: #{pin_num} value: #{val}"
            Farmbot.CeleryScript.var(env, label, val)
          {:error, reason} -> {:error, reason, env}
        end
      {:error, reason} -> {:error, reason, env}
    end
  end
end
