defmodule FarmbotCeleryScript.CompilerTest do
  use ExUnit.Case, async: true
  alias FarmbotCeleryScript.{AST, Compiler}
  # Only required to compile
  alias FarmbotCeleryScript.SysCalls, warn: false

  test "compiles a sequence with no body" do
    sequence = %AST{
      args: %{
        locals: %AST{
          args: %{},
          body: [],
          comment: nil,
          kind: :scope_declaration
        },
        version: 20_180_209
      },
      body: [],
      comment: "This is the root",
      kind: :sequence
    }

    body = Compiler.compile(sequence)
    assert body == []
  end

  test "identifier sanitization" do
    label = "System.cmd(\"rm\", [\"-rf /*\"])"
    value_ast = AST.Factory.new("coordinate", x: 1, y: 1, z: 1)
    identifier_ast = AST.Factory.new("identifier", label: label)

    parameter_application_ast =
      AST.Factory.new("parameter_application", label: label, data_value: value_ast)

    celery_ast = %AST{
      kind: :sequence,
      args: %{
        locals: %{
          kind: :scope_declaration,
          args: %{},
          body: [
            parameter_application_ast
          ]
        }
      },
      body: [
        identifier_ast
      ]
    }

    elixir_ast = Compiler.compile_ast(celery_ast)

    elixir_code =
      elixir_ast
      |> Macro.to_string()
      |> Code.format_string!()
      |> IO.iodata_to_binary()

    var_name = Compiler.IdentifierSanitizer.to_variable(label)

    assert elixir_code =~ """
             #{var_name} = coordinate(1, 1, 1)
             [fn -> #{var_name} end]
           """

    refute String.contains?(elixir_code, label)
    {fun, _} = Code.eval_string(elixir_code, [], __ENV__)
    assert is_function(fun, 1)
  end

  # defp fixture(filename) do
  #   filename
  #   |> Path.expand("fixture")
  #   |> File.read!()
  #   |> Jason.decode!()
  #   |> AST.decode()
  # end
end
