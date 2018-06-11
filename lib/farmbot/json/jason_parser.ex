defmodule Farmbot.JSON.JasonParser do
  @moduledoc "Parser handler for Jason"
  @behaviour Farmbot.JSON.Parser

  def decode(data), do: Jason.decode(data)
  def encode(data), do: Jason.encode(data)

  require Protocol
  Protocol.derive(Jason.Encoder, Farmbot.Jwt)
end
