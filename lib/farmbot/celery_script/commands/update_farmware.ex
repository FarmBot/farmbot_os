defmodule Farmbot.CeleryScript.Command.UpdateFarmware do
  @moduledoc """
    Update Farmware
  """

  alias      Farmbot.CeleryScript.{Command, Error, Types}
  alias      Farmbot.Context
  require    Logger
  @behaviour Command

  @doc ~s"""
    Update a farmware
      args: %{package: String.t},
      body: []
  """
  @spec run(%{package: Types.package}, [], Context.t) :: Context.t
  def run(%{package: name}, [], context) do
    Logger.info "Updating a Farmware!", type: :busy
    case Farmbot.Farmware.Manager.lookup_by_name(context, name) do
      {:ok, fw} ->
        Farmbot.Farmware.Installer.install! context, fw.url
        Logger.info "Updated: #{fw.name}", type: :success
        context
      {:error, e} ->
        Farmbot.Farmware.Manager.reindex(context)
        raise Error, context: context,
          message: "Could not locate farmware: #{e}"
    end
  end
end
