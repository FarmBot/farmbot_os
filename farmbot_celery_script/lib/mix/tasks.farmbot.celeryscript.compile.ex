defmodule Mix.Tasks.Farmbot.CeleryScript.Compile do
  @moduledoc """
  Compile a json representation of CeleryScript

  # Usage
      mix farmbot.celery_script.compile [switches] input1.json input2.json

  # Switches
  * `--out filename.exs` (default=stdout) - Output compiled Elixir code to `filename.exs`
  * `--ast filename.exs` (default=false)  - Output Elixir AST to `filename.exs`
  * `--format false`     (default=true)   - Format the resulting code 
  """
  @shortdoc true

  alias Farmbot.CeleryScript.AST

  use Mix.Task

  @options [
    strict: [
      out: :string,
      ast: :string,
      format: :boolean,
      help: :boolean
    ],
    aliases: [
      o: :out,
      a: :ast,
      f: :format
    ]
  ]

  def run(args) do
    {switches, files, _} = OptionParser.parse(args, @options)
    output_filename = Keyword.get(switches, :out, "stdout")
    ast_filename = Keyword.get(switches, :ast, false)
    format = Keyword.get(switches, :format, true)

    if Keyword.get(switches, :help, false) do
      Mix.Task.run("help", ["farmbot.celery_script.compile"])
      System.halt(0)
    end

    asts =
      Enum.map(files, fn filename ->
        filename
        |> File.read!()
        |> Jason.decode!()
        |> case do
          %{} = data -> [AST.decode(data)]
          data when is_list(data) -> Enum.map(data, &AST.decode/1)
        end
        |> Enum.map(&AST.compile/1)
      end)

    case ast_filename do
      false ->
        asts

      "stdout" ->
        IO.inspect(asts, limit: :infinity)

      filename ->
        File.write!(filename, inspect(asts, limit: :infinity))
        asts
    end

    code =
      asts
      |> Macro.to_string()
      |> case do
        code when format == true ->
          Code.format_string!(code) |> to_string()

        code ->
          code
      end

    case output_filename do
      "stdout" ->
        IO.puts(code)

      filename ->
        File.write!(filename, code)
    end
  end
end
