defmodule EarmarkParser.Ast.Renderer.HtmlRenderer do

  import EarmarkParser.Context, only: [prepend: 2]
  import EarmarkParser.Helpers.HtmlParser

  @moduledoc false

  # Structural Renderer for html blocks
  def render_html_block(lines, context) do
    [tag] = parse_html(lines)
    prepend(context, tag)
  end

  def render_html_oneline([line|_], context) do
    prepend(context, parse_html([line]))
  end
  
  @html_comment_start ~r{\A\s*<!--}
  @html_comment_end ~r{-->.*\z}
  def render_html_comment_line(line) do
    line
    |> String.replace(@html_comment_start, "")
    |> String.replace(@html_comment_end, "")
  end

end
