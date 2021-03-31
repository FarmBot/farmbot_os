defmodule ElixirMake.Mixfile do
  use Mix.Project

  @version "0.6.2"

  def project do
    [
      app: :elixir_make,
      version: @version,
      elixir: "~> 1.3",
      description: "A Make compiler for Mix",
      package: package(),
      docs: docs(),
      deps: [{:ex_doc, "~> 0.20", only: :docs}]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: []]
  end

  defp package do
    %{
      licenses: ["Apache 2"],
      links: %{"GitHub" => "https://github.com/elixir-lang/elixir_make"},
      maintainers: ["Andrea Leopardi", "José Valim"]
    }
  end

  defp docs do
    [
      main: "Mix.Tasks.Compile.ElixirMake",
      source_ref: "v#{@version}",
      source_url: "https://github.com/elixir-lang/elixir_make"
    ]
  end
end
