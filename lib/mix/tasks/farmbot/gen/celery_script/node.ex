defmodule Mix.Tasks.Farmbot.Gen.CeleryScript.Node do
  @moduledoc "Generate a CeleryScript Node."
  use Mix.Task

  @usage """
  usage:
    mix farmbot.celery_script.gen.node SomeCamelModuleName --args comma,seperated,list,of,args
  """

  @shortdoc @moduledoc
  @code_template_path "lib/mix/tasks/farmbot/gen/celery_script/node.ex.eex"
  @test_template_path "lib/mix/tasks/farmbot/gen/celery_script/node_test.ex.eex"

  @node_path "lib/farmbot/celery_script/ast/node/"
  @test_path "test/farmbot/celery_script/ast/node/"

  def run([]) do
    Mix.raise @usage
  end

  def run(args) do
    case OptionParser.parse(args) do
      {opts, [module], _} ->
        namespace = Module.split(Farmbot.CeleryScript.AST.Node)
        full_mod = [namespace | [module]] |> List.flatten |> Module.concat()
        allow_args = check_args(opts)
        code = EEx.eval_file(@code_template_path, [module: full_mod |> to_string() |> String.trim_leading("Elixir."), allow_args: allow_args])
        test = EEx.eval_file(@test_template_path, [module: full_mod |> to_string() |> String.trim_leading("Elixir."), alias_module: module])
        do_write_files(module, full_mod, code, test)
      _ ->
        Mix.raise @usage
    end
  end

  defp check_args(opts) do
    cs_args = Keyword.get(opts, :args, [])
    arg_list = String.split(cs_args, ",")
    allow_args = Enum.map(arg_list, fn(arg) ->
      a = Macro.camelize(arg)
      namespace = Module.split(Farmbot.CeleryScript.AST.Arg)
      full_mod = [namespace | [a]] |> List.flatten |> Module.concat()
      unless Code.ensure_loaded?(full_mod) do
        Mix.raise "Unknown arg: #{arg} (#{full_mod})"
      end
      String.to_atom(arg)
    end)

    allow_args
  end

  defp do_write_files(module, full_mod, code, test) do
    case Code.eval_string(code) do
      {{:module, ^full_mod, _, _}, _} ->
        code_file_name = Macro.underscore(module) <> ".ex"
        code_file_path = Path.join(@node_path, code_file_name)
        if File.exists?(code_file_path) do
          Mix.raise "#{code_file_path} already exists."
        end
        File.write!(code_file_path, code)

        test_file_name = Macro.underscore(module) <> "_test.exs"
        test_file_path = Path.join(@test_path, test_file_name)
        if File.exists?(test_file_path) do
          Mix.raise "#{test_file_path} already exists."
        end
        File.write!(test_file_path, test)
        Mix.shell.info [:green, "New node; #{code_file_path}"]

      _ -> Mix.raise "Invalid module: #{module}"
    end
  end

end
