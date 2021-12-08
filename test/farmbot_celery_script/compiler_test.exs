defmodule FarmbotOS.Celery.CompilerTest do
  use ExUnit.Case
  use Mimic

  alias FarmbotOS.Celery.{AST, Compiler}
  alias FarmbotOS.Celery.Compiler.Scope
  # Only required to compile
  alias FarmbotOS.Celery.SysCallGlue, warn: false

  test "change_ownership" do
    email = "t@g.com"
    secret = "super duper"
    server = "https://my.farm.bot"

    body = [
      %{args: %{label: "email", value: email}},
      %{args: %{label: "secret", value: secret}},
      %{args: %{label: "server", value: server}}
    ]

    expect(FarmbotOS.SysCalls.ChangeOwnership, :change_ownership, 1, fn eml,
                                                                        scrt,
                                                                        srvr ->
      assert eml == email
      assert scrt == "\xB2\xEA^\xAD۩z"
      assert srvr == server
      :ok
    end)

    result =
      FarmbotOS.Celery.Compiler.change_ownership(%{body: body}, Scope.new())
      |> Code.eval_quoted()

    assert result == {:ok, []}
  end

  test "send_message/2" do
    channels = [%{kind: :channel, args: %{channel_name: "email"}}]
    type = "fun"
    msg = "Hello, world!"
    args = %{args: %{message: msg, message_type: type}, body: channels}

    expect(FarmbotOS.Celery.SysCallGlue, :send_message, 1, fn t, m, c ->
      assert t == type
      assert m == msg
      assert c == [:email]
      :ok
    end)

    result =
      FarmbotOS.Celery.Compiler.send_message(args, Scope.new())
      |> Code.eval_quoted()

    assert result == {:ok, []}
  end

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
                default_value: %AST{
                  kind: :coordinate,
                  args: %{
                    x: 333,
                    y: 444,
                    z: 555
                  }
                }
              }
            }
          ]
        }
      },
      body: [
        %AST{kind: :identifier, args: %{label: "provided_by_caller"}}
      ]
    }

    {executable, _} =
      sequence
      |> Compiler.compile(Scope.new())
      |> Enum.at(0)
      |> Macro.to_string()
      |> Code.eval_string()

    variable =
      executable
      |> apply([])
      |> Enum.at(1)
      |> apply([])

    assert variable.args.x == 333
    assert variable.args.y == 444
    assert variable.args.z == 555
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
             FarmbotOS.Celery.SysCallGlue.log(\"Taking photo\", true)
             FarmbotOS.Celery.SysCallGlue.execute_script(package, env)
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
             FarmbotOS.Celery.SysCallGlue.set_user_env("a", "123")
             FarmbotOS.Celery.SysCallGlue.set_user_env("b", "345")
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
             FarmbotOS.Celery.SysCallGlue.nothing()
             """)
  end

  test "compiles move_absolute with tool_id" do
    expect(SysCallGlue.Stubs, :get_toolslot_for_tool, 1, fn
      222 -> %{gantry_mounted: false, name: "X", x: 220, y: 221, z: 222}
      id -> raise "Wrong id: #{id}"
    end)

    expect(SysCallGlue.Stubs, :move_absolute, 1, fn x, y, z, s ->
      assert {219, 220, 221, 100} == {x, y, z, s}
      :ok
    end)

    move_abs = %AST{
      kind: :move_absolute,
      args: %{
        speed: 100,
        location: %AST{
          kind: :tool,
          args: %{
            tool_id: 222
          }
        },
        offset: %AST{
          kind: :coordinate,
          args: %{x: -1, y: -1, z: -1}
        }
      },
      body: []
    }

    {result, _} =
      move_abs
      |> Compiler.celery_to_elixir(Scope.new())
      |> Macro.to_string()
      |> Code.eval_string()

    assert result == :ok
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

    expected =
      "[x, y, z] = [100 + -20, 100 + -20, 100 + -20] x_str = FarmbotOS.Celery.FormatUtil.format_float(x) y_str = FarmbotOS.Celery.FormatUtil.format_float(y) z_str = FarmbotOS.Celery.FormatUtil.format_float(z) FarmbotOS.Celery.SysCallGlue.log(\"Moving to (\#{x_str}, \#{y_str}, \#{z_str})\", true) FarmbotOS.Celery.SysCallGlue.move_absolute(x, y, z, 100)"

    assert compiled == expected
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
               curx when is_number(curx) <- FarmbotOS.Celery.SysCallGlue.get_current_x(),
               cury when is_number(cury) <- FarmbotOS.Celery.SysCallGlue.get_current_y(),
               curz when is_number(curz) <- FarmbotOS.Celery.SysCallGlue.get_current_z()
             ) do
               x = locx + curx
               y = locy + cury
               z = locz + curz
               x_str = FarmbotOS.Celery.FormatUtil.format_float(x)
               y_str = FarmbotOS.Celery.FormatUtil.format_float(y)
               z_str = FarmbotOS.Celery.FormatUtil.format_float(z)
               FarmbotOS.Celery.SysCallGlue.log("Moving relative to (\#{x_str}, \#{y_str}, \#{z_str})", true)
               FarmbotOS.Celery.SysCallGlue.move_absolute(x, y, z, 100)
             end
             """)
  end

  # test "compiles write_pin" do
  #   compiled =
  #     compile(%AST{
  #       kind: :write_pin,
  #       args: %{pin_number: 17, pin_mode: 0, pin_value: 1}
  #     })

  #   expected =
  #     "pin = 17\nmode = 0\nvalue = 1\n\nwith(:ok <- " <>
  #       "FarmbotOS.Celery.SysCallGlue.write_pin(pin, mode, value))" <>
  #       " do\n  me = FarmbotOS.Celery.Compiler.PinControl\n" <>
  #       "  me.conclude(pin, mode, value)\nend"

  #   assert compiled == expected
  # end

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
             FarmbotOS.Celery.SysCallGlue.read_pin(pin, mode)
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
             FarmbotOS.Celery.SysCallGlue.log("Writing servo: \#{pin}: \#{angle}")
             FarmbotOS.Celery.SysCallGlue.set_servo_angle(pin, angle)
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
             FarmbotOS.Celery.SysCallGlue.log("Setting pin mode: \#{pin}: \#{mode}")
             FarmbotOS.Celery.SysCallGlue.set_pin_io_mode(pin, mode)
             """)
  end

  test "`abort`" do
    ast = %AST{kind: :abort}
    func = Compiler.compile(ast, Scope.new())
    assert func.() == {:error, "aborted"}
  end

  test "lua in RPC, no variable declarations" do
    example = %FarmbotOS.Celery.AST{
      args: %{
        label: "abcdefgh"
      },
      body: [
        %FarmbotOS.Celery.AST{
          args: %{
            lua: """
              usage = read_status('informational_settings').scheduler_usage
              send_message('warn', usage, 'toast');
            """
          },
          body: [],
          comment: nil,
          kind: :lua,
          meta: nil
        }
      ],
      comment: nil,
      kind: :rpc_request,
      meta: nil
    }

    result = Compiler.compile(example, Scope.new())
    # Previously, this would crash because
    # `cs_scope` was not declared.
    assert result
  end

  defp compile(ast) do
    ast
    |> Compiler.celery_to_elixir(Scope.new())
    |> Macro.to_string()
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> strip_nl()
  end

  defp strip_nl(text) do
    text
    |> String.trim_trailing("\n")
    |> String.replace(~r/\s+/, " ")
  end
end
