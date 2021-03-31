defmodule ExCoveralls.Html.View do
  @moduledoc """
  Conveniences for generating HTML.
  """
  require EEx
  require ExCoveralls.Html.Safe

  alias ExCoveralls.Html.Safe

  defmodule PathHelper do
    def template_path(template) do
      template |> Path.expand(get_template_path())
    end

    defp get_template_path() do
      options = ExCoveralls.Settings.get_coverage_options
      case Map.fetch(options, "template_path") do
        {:ok, path} -> path
        _ -> Path.expand("excoveralls/lib/templates/html/htmlcov/", Mix.Project.deps_path())
      end
    end
  end

  @template "coverage.html.eex"

  def render(assigns \\ []) do
    EEx.eval_file(PathHelper.template_path(@template), assigns: assigns)
  end

  def partial(template, assigns \\ []) do
    EEx.eval_file(PathHelper.template_path(template), assigns: assigns)
  end

  def safe(data) do
    Safe.html_escape(data)
  end

  def coverage_class(percent, sloc \\ nil)
  def coverage_class(_percent, 0), do: "none"
  def coverage_class(percent, _) do
    cond do
      percent >= 75 -> "high"
      percent >= 50 -> "medium"
      percent >= 25 -> "low"
      true -> "terrible"
    end
  end
end
