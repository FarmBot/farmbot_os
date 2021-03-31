defmodule EarmarkParser.Helpers do

  @moduledoc false
  @doc """
  Expand tabs to multiples of 4 columns
  """
  def expand_tabs(line) do
    Regex.replace(~r{(.*?)\t}, line, &expander/2)
  end

  defp expander(_, leader) do
    extra = 4 - rem(String.length(leader), 4)
    leader <> pad(extra)
  end

  @doc """
  Remove newlines at end of line
  """
  def remove_line_ending(line) do
    line |> String.trim_trailing("\n") |> String.trim_trailing("\r")
  end

  defp pad(1), do: " "
  defp pad(2), do: "  "
  defp pad(3), do: "   "
  defp pad(4), do: "    "

  @doc """
  `Regex.replace` with the arguments in the correct order
  """

  def replace(text, regex, replacement, options \\ []) do
    Regex.replace(regex, text, replacement, options)
  end

  @doc """
  Replace <, >, and quotes with the corresponding entities. If
  `encode` is true, convert ampersands, too, otherwise only
   convert non-entity ampersands.
  """

  @amp_rgx ~r{&(?!#?\w+;)}
  @never_amp_rgx ~r{&(?!#x[0-9a-f]+;)}i
  def escape(html, encode \\ false)

  def escape(html, false), do: _escape(Regex.replace(@amp_rgx, html, "&amp;"))

  def escape(html, _), do: _escape(Regex.replace(@never_amp_rgx, html, "&amp;"))

  defp _escape(html) do
    html
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end

# SPDX-License-Identifier: Apache-2.0
