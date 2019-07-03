defmodule FarmbotCore.Asset.BoxLed do
  @moduledoc """
  """

  defstruct [:id]

  defimpl String.Chars, for: FarmbotCore.Asset.BoxLed do
    def to_string(%FarmbotCore.Asset.BoxLed{id: id}) do
      "BoxLed #{id}"
    end
  end
end
