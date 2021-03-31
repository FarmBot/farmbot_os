defmodule ExCoveralls.Html.Safe do
  @moduledoc """
  Conveniences for generating HTML.
  """

  @doc ~S"""
  Escapes the given HTML.
  """
  def html_escape(data) when is_binary(data) do
    IO.iodata_to_binary(for <<char <- data>>, do: escape_char(char))
  end

  @compile {:inline, escape_char: 1}

  @escapes [
    {?<, "&lt;"},
    {?>, "&gt;"},
    {?&, "&amp;"},
    {?", "&quot;"},
    {?', "&#39;"}
  ]

  Enum.each @escapes, fn { match, insert } ->
    defp escape_char(unquote(match)), do: unquote(insert)
  end

  defp escape_char(char), do: char
end
