defmodule Farmbot.Repo.ModuleType.Point do
  use Farmbot.Repo.ModuleType, valid_mods: ~w(GenericPointer, ToolSlot, Plant)
end
