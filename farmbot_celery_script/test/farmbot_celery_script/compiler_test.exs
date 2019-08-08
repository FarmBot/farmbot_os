defmodule FarmbotCeleryScript.CompilerTest do
  use ExUnit.Case, async: true
  alias FarmbotCeleryScript.{AST, Compiler}
  # Only required to compile
  alias FarmbotCeleryScript.SysCalls, warn: false
  alias FarmbotCeleryScript.Compiler.IdentifierSanitizer

  test "compiles a sequence with unbound variables" do
    sequence = %AST{
      kind: :sequence,
      args: %{
        locals: %AST{
          kind: :scope_declaration,
          args: %{},
          body: [
            %AST{
              kind: :parameter_declaration,
              args: %{
                label: "provided_by_caller",
                default_value: 100
              }
            }
          ]
        }
      },
      body: [
        %AST{kind: :identifier, args: %{label: "provided_by_caller"}}
      ]
    }

    [body_item] = Compiler.compile(sequence)
    assert body_item.() == 100

    # The compiler expects the `env` argument to be already sanatized.
    # When supplying the env for this test, we need to make sure the
    # `provided_by_caller` variable name is sanatized
    sanatized_env = [{IdentifierSanitizer.to_variable("provided_by_caller"), 900}]
    [body_item] = Compiler.compile(sequence, sanatized_env)
    assert body_item.() == 900

    celery_env = [
      %AST{
        kind: :parameter_application,
        args: %{
          label: "provided_by_caller",
          data_value: 600
        }
      }
    ]

    compiled_celery_env = Compiler.compile_params_to_function_args(celery_env)
    [body_item] = Compiler.compile(sequence, compiled_celery_env)
    assert body_item.() == 600
  end

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

    assert elixir_code =~
             strip_nl("""
             fn params ->
               _ = inspect(params)
               #{var_name} = FarmbotCeleryScript.SysCalls.coordinate(1, 1, 1)
               [fn -> #{var_name} end]
             end
             """)

    refute String.contains?(elixir_code, label)
    {fun, _} = Code.eval_string(elixir_code, [], __ENV__)
    assert is_function(fun, 1)
  end

  test "compiles execute" do
    compiled =
      compile(%AST{
        kind: :execute,
        args: %{sequence_id: 100},
        body: []
      })

    assert compiled ==
             strip_nl("""
             case(FarmbotCeleryScript.SysCalls.get_sequence(100)) do
               %FarmbotCeleryScript.AST{} = ast ->
                 env = []
                 FarmbotCeleryScript.Compiler.compile(ast, env)

               error ->
                 error
             end
             """)
  end

  test "compiles execute_script" do
    compiled =
      compile(%AST{
        kind: :execute_script,
        args: %{label: "take-photo"},
        body: [
          %AST{kind: :pair, args: %{label: "a", value: "123"}}
        ]
      })

    assert compiled ==
             strip_nl("""
             package = "take-photo"
             env = %{"a" => "123"}
             FarmbotCeleryScript.SysCalls.log("Executing Farmware: \#{package}")
             FarmbotCeleryScript.SysCalls.execute_script(package, env)
             """)
  end

  test "compiles set_user_env" do
    compiled =
      compile(%AST{
        kind: :set_user_env,
        args: %{},
        body: [
          %AST{kind: :pair, args: %{label: "a", value: "123"}},
          %AST{kind: :pair, args: %{label: "b", value: "345"}}
        ]
      })

    assert compiled ==
             strip_nl("""
             FarmbotCeleryScript.SysCalls.set_user_env("a", "123")
             FarmbotCeleryScript.SysCalls.set_user_env("b", "345")
             """)
  end

  test "install_first_party_farmware" do
    compiled =
      compile(%AST{
        kind: :install_first_party_farmware,
        args: %{},
        body: []
      })

    assert compiled ==
             strip_nl("""
             FarmbotCeleryScript.SysCalls.log("Installing first party Farmware")
             FarmbotCeleryScript.SysCalls.install_first_party_farmware()
             """)
  end

  test "compiles nothing" do
    compiled =
      compile(%AST{
        kind: :nothing,
        args: %{},
        body: []
      })

    assert compiled ==
             strip_nl("""
             FarmbotCeleryScript.SysCalls.nothing()
             """)
  end

  test "compiles move_absolute no variables" do
    compiled =
      compile(%AST{
        kind: :move_absolute,
        args: %{
          speed: 100,
          location: %AST{
            kind: :coordinate,
            args: %{x: 100, y: 100, z: 100}
          },
          offset: %AST{
            kind: :coordinate,
            args: %{x: -20, y: -20, z: -20}
          }
        },
        body: []
      })

    assert compiled ==
             strip_nl("""
             with(
               %{x: locx, y: locy, z: locz} = FarmbotCeleryScript.SysCalls.coordinate(100, 100, 100),
               %{x: offx, y: offy, z: offz} = FarmbotCeleryScript.SysCalls.coordinate(-20, -20, -20)
             ) do
               [x, y, z] = [locx + offx, locy + offy, locz + offz]
               x_str = FarmbotCeleryScript.FormatUtil.format_float(x)
               y_str = FarmbotCeleryScript.FormatUtil.format_float(y)
               z_str = FarmbotCeleryScript.FormatUtil.format_float(z)
               FarmbotCeleryScript.SysCalls.log("Moving to (\#{x_str}, \#{y_str}, \#{z_str})")
               FarmbotCeleryScript.SysCalls.move_absolute(x, y, z, 100)
             end
             """)
  end

  test "compiles move_relative" do
    compiled =
      compile(%AST{
        kind: :move_relative,
        args: %{
          x: 100.4,
          y: 90,
          z: 50,
          speed: 100
        }
      })

    assert compiled ==
             strip_nl("""
             with(
               locx when is_number(locx) <- 100.4,
               locy when is_number(locy) <- 90,
               locz when is_number(locz) <- 50,
               curx when is_number(curx) <- FarmbotCeleryScript.SysCalls.get_current_x(),
               cury when is_number(cury) <- FarmbotCeleryScript.SysCalls.get_current_y(),
               curz when is_number(curz) <- FarmbotCeleryScript.SysCalls.get_current_z()
             ) do
               x = locx + curx
               y = locy + cury
               z = locz + curz
               x_str = FarmbotCeleryScript.FormatUtil.format_float(x)
               y_str = FarmbotCeleryScript.FormatUtil.format_float(y)
               z_str = FarmbotCeleryScript.FormatUtil.format_float(z)
               FarmbotCeleryScript.SysCalls.log("Moving relative to (\#{x_str}, \#{y_str}, \#{z_str})")
               FarmbotCeleryScript.SysCalls.move_absolute(x, y, z, 100)
             end
             """)
  end

  test "compiles write_pin" do
    compiled =
      compile(%AST{
        kind: :write_pin,
        args: %{pin_number: 17, pin_mode: 0, pin_value: 1}
      })

    assert compiled ==
             strip_nl("""
             pin = 17
             mode = 0
             value = 1

             with(:ok <- FarmbotCeleryScript.SysCalls.write_pin(pin, mode, value)) do
               FarmbotCeleryScript.SysCalls.read_pin(pin, mode)
             end
             """)
  end

  test "compiles read pin" do
    compiled =
      compile(%AST{
        kind: :read_pin,
        args: %{pin_number: 23, pin_mode: 0}
      })

    assert compiled ==
             strip_nl("""
             pin = 23
             mode = 0
             FarmbotCeleryScript.SysCalls.read_pin(pin, mode)
             """)
  end

  test "compiles set_servo_angle" do
    compiled =
      compile(%AST{
        kind: :set_servo_angle,
        args: %{pin_number: 23, pin_value: 90}
      })

    assert compiled ==
             strip_nl("""
             pin = 23
             angle = 90
             FarmbotCeleryScript.SysCalls.log("Writing servo: \#{pin}: \#{angle}")
             FarmbotCeleryScript.SysCalls.set_servo_angle(pin, angle)
             """)
  end

  test "compiles set_pin_io_mode" do
    compiled =
      compile(%AST{
        kind: :set_pin_io_mode,
        args: %{pin_number: 23, pin_io_mode: "input"}
      })

    assert compiled ==
             strip_nl("""
             pin = 23
             mode = "input"
             FarmbotCeleryScript.SysCalls.log("Setting pin mode: \#{pin}: \#{mode}")
             FarmbotCeleryScript.SysCalls.set_pin_io_mode(pin, mode)
             """)
  end

  defp compile(ast) do
    ast
    |> Compiler.compile_ast()
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
  end

  defp strip_nl(text) do
    String.trim_trailing(text, "\n")
  end
end
