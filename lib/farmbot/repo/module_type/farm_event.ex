defmodule Farmbot.Repo.ModuleType.FarmEvent do
  @moduledoc false
  use Farmbot.Repo.ModuleType, valid_mods: ~w(Sequence Regimen)
end
