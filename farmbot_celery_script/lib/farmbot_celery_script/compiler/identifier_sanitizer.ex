defmodule Farmbot.CeleryScript.Compiler.IdentifierSanitizer do
  @moduledoc """
  Responsible for ensuring variable names in Sequences are clean.
  """

  @token "unsafe_"

  @doc """
  Takes an unsafe string, and returns a safe variable name.
  """
  def to_variable(string) when is_binary(string) do
    String.to_atom(@token <> Base.url_encode64(string, padding: false))
  end

  @doc "Takes an encoded safe variable name and returns the original unsafe string."
  def to_string(<<@token <> encoded>>) do
    Base.url_decode64!(encoded, padding: false)
  end
end
