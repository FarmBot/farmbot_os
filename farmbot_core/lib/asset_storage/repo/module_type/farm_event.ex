defmodule Farmbot.Asset.Repo.ModuleType.FarmEvent do
  @moduledoc false
  use Farmbot.Asset.Repo.ModuleType, valid_mods: ~w(Sequence Regimen)
end
