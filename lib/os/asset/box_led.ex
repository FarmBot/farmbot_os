defmodule FarmbotOS.Asset.BoxLed do
  @moduledoc """
  """

  defstruct [:id]

  defimpl String.Chars, for: FarmbotOS.Asset.BoxLed do
    def to_string(%FarmbotOS.Asset.BoxLed{id: id}) do
      "BoxLed #{id}"
    end
  end
end
