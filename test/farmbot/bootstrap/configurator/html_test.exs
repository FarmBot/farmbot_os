defmodule Farmbot.Bootstrap.Configurator.HTMLTest do
  @moduledoc "Tests HTML helpers."
  alias Farmbot.Bootstrap.Configurator.HTML
  use ExUnit.Case

  @priv_dir "#{:code.priv_dir(:farmbot)}"

  test "evaluates a file" do
    assert File.exists?(Path.join([@priv_dir, "templates", "page.html.eex"]))
    assert HTML.eval_file("page", [page: 0, render: fn() -> :ok end, conn: %{__struct__: H, private: %{}}])
  end

  test "renders a file" do
    assert File.exists?(Path.join([@priv_dir, "templates", "page", "page0.html.eex"]))
    assert HTML.render("page0")
  end
end
