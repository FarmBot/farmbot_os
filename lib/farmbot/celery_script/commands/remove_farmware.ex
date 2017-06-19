defmodule Farmbot.CeleryScript.Command.RemoveFarmware do
  @moduledoc """
    Uninstall Farmware
  """

  alias      Farmbot.CeleryScript.{Command, Error}
  alias      Farmbot.Context
  import     Farmbot.Lib.Helpers
  require    Logger
  @behaviour Command

  @doc ~s"""
    Uninstall a farmware
      args: %{package: uuid},
      body: []
  """
  @spec run(%{package: binary}, [], Context.t) :: Context.t
  def run(%{package: uuid}, [], %Context{} = context) when is_uuid(uuid) do
    Logger.info "Uninstalling a Farmware!", type: :busy
    fw = Farmbot.Farmware.Manager.uninstall! context, uuid
    Logger.info "Uninstalled: #{fw.name}", type: :success
    context
  end

  def run(%{package: _not_uuid}, _, %Context{} = context) do
    raise Error, context: context,
      message: "To uninstall a farmware, please supply a UUID."
  end
end
