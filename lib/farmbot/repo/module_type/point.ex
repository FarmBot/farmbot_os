defmodule Farmbot.Repo.ModuleType.Point do
  @moduledoc false
  use Farmbot.Repo.ModuleType, valid_mods: ~w(GenericPointer ToolSlot Plant)
end
