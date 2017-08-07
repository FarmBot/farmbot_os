defmodule Farmbot.CeleryScript.Command.RemoveFarmware do
  @moduledoc """
    Uninstall Farmware
  """

  alias      Farmbot.CeleryScript.{Command, Error}
  alias      Farmbot.Context
  require    Logger
  @behaviour Command

  @doc ~s"""
    Uninstall a farmware
      args: %{package: name},
      body: []
  """
  @spec run(%{package: binary}, [], Context.t) :: Context.t
  def run(%{package: name}, [], %Context{} = context) do
    Logger.info "Uninstalling a Farmware!", type: :busy
    case Farmbot.Farmware.Manager.lookup_by_name(context, name) do
      {:ok, fw} ->
        Farmbot.Farmware.Installer.uninstall! context, fw
        Logger.info "Uninstalled: #{fw.name}", type: :success
        context
      {:error, e} ->
        Farmbot.Farmware.Manager.reindex(context)
        raise Error, context: context,
          message: "Could not locate farmware: #{e}"
    end
  end
end
