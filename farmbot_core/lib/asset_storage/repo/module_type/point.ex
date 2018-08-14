defmodule Farmbot.EctoTypes.ModuleType.Point do
  @moduledoc false
  use Farmbot.EctoTypes.ModuleType, valid_mods: ~w(GenericPointer ToolSlot Plant)
end
