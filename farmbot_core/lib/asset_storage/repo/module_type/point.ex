defmodule Farmbot.Asset.Repo.ModuleType.Point do
  @moduledoc false
  use Farmbot.Asset.Repo.ModuleType, valid_mods: ~w(GenericPointer ToolSlot Plant)
end
