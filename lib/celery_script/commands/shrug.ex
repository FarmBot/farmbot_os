defmodule Farmbot.CeleryScript.Command.Shrug do
  @moduledoc """
    Shrug
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @shrug "¯\\\\_(ツ)_/\¯"

  @doc ~s"""
    Sends a warning message. Used for denoting hax and what not
      args: %{message: String.t}
      body: []
  """
  @spec run(%{messsage: String.t}, []) :: no_return
  def run(%{message: str}, []) do
    Command.send_message(%{message: str <> @shrug, message_type: :warn}, [])
  end
end
