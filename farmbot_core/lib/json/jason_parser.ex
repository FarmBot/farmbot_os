defmodule Farmbot.JSON.JasonParser do
  @moduledoc "Parser handler for Jason"
  @behaviour Farmbot.JSON.Parser

  def decode(data, opts), do: Jason.decode(data, opts)
  def encode(data, opts), do: Jason.encode(data, opts)
end
