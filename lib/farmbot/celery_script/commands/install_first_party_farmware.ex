defmodule Farmbot.CeleryScript.Command.InstallFirstPartyFarmware do
  @moduledoc """
  Install first party farmware.
  """

  alias Farmbot.CeleryScript.Command
  @behaviour Command

  @doc ~s"""
  args: %{}
  body: []
  """
  @spec run(%{}, [], Context.t) :: Context.t
  def run(%{}, [], context) do
    repo = Farmbot.Farmware.Installer.Repository.Farmbot
    Farmbot.Farmware.Installer.enable_repo!(context, repo)
    context
  end

end
