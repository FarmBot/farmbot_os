defmodule Farmbot.CeleryScript.AST.Pretty do
  @moduledoc false

  @default_indent 2
  @default_offset 0

  defp pretty(options) do
    !!Map.get(options, :pretty)
  end

  defp indent(options) do
    Map.get(options, :indent, @default_indent)
  end

  defp offset(options) do
    Map.get(options, :offset, @default_offset)
  end

  defp offset(options, value) do
    Map.put(options, :offset, value)
  end

  defp spaces(count) do
    :binary.copy(" ", count)
  end

  def print(ast) do
    IO.puts(format(ast, %{pretty: true}))
  end

  def format(ast, opts) do
    format(ast, pretty(opts), opts)
  end

  def format(ast, true, opts) do
    indent = indent(opts)
    offset = if(indent == 0, do: offset(opts) + 2, else: offset(opts) + indent)
    options = offset(opts, offset)
    # args = Enum.map(ast.args, fn({k, v}) -> "#{k}=#{format(v, %{pretty: true})}" end) |> Enum.join(", ")
    args = Enum.map(ast.args, fn({k, _v}) -> "#{k}" end) |> Enum.join(", ")
    body = if(ast.body == [], do: "[]", else: "\n#{Enum.map(ast.body, fn(sub_ast) -> format(sub_ast, options) end) |> Enum.join("#{spaces(offset)}\n")}\n")
    do_  = if(ast.body == [], do: nil,  else: "[")
    end_ = if(ast.body == [], do: nil,  else: "]")
    "#{spaces(offset)}#{Module.split(ast.kind) |> List.last() |> Macro.underscore()}(#{args}) #{do_}#{body}#{spaces(offset)}#{end_}"
  end
end
