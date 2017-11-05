defmodule Farmbot.CeleryScript.AST.Node.InstallFarmware do
  @moduledoc false
  use Farmbot.CeleryScript.AST.Node
  allow_args [:url]

  def execute(%{url: url}, _, env) do
    case Farmbot.Farmware.Installer.install(url) do
      {:ok, _} -> {:ok, env}
      {:error, reason} -> {:error, reason, env}
    end
  end
end
