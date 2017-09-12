defmodule Farmbot.Bootstrap.Configurator.HTML do
  @moduledoc """
  Helpers for HTML parsing and stuff.
  """

  @doc "Helper for evaulating a file."
  def eval_file(file, opts \\ []) do
    EEx.eval_file("#{:code.priv_dir(:farmbot)}/templates/#{file}.html.eex", opts)
  end

  @doc "Render a page in the `priv/templates/page` dir."
  def render(page) do
    eval_file("page", [page: page, render: fn -> eval_file("page/#{page}") end])
  end
end
