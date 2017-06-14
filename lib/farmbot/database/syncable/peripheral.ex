defmodule Farmbot.Database.Syncable.Peripheral do
  @moduledoc """
    A Peripheral from the Farmbot API.
  """

  alias Farmbot.Database
  alias Database.Syncable
  alias Farmbot.Context
  alias Farmbot.CeleryScript.{Command, Ast}

  use Syncable, model: [
    :pin,
    :mode,
    :label
  ], endpoint: {"/peripherals", "/peripherals"}

  def on_fetch(context, object_or_list)

  def on_fetch(%Context{} = _, []), do: :ok

  def on_fetch(%Context{} = context, [%__MODULE__{} = first | rest]) do
    on_fetch(context, first)
    on_fetch(context, rest)
  end

  def on_fetch(%Context{} = context, %__MODULE__{pin: pin, mode: mode, label: label}) do
    spawn fn ->
      :ok = Farmbot.BotState.set_pin_mode(context, pin, mode)
      ast = %Ast{
        kind: "read_pin",
        args: %{pin_number: pin, pin_mode: mode, label: label},
        body: []
      }
      Command.do_command(ast, context)
    end
  end
end
