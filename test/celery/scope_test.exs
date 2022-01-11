defmodule FarmbotOS.Celery.Compiler.ScopeTest do
  use ExUnit.Case
  alias FarmbotOS.Celery.AST
  alias FarmbotOS.Celery.Compiler.Scope

  @fixture "test/fixtures/execute.json"
           |> File.read!()
           |> Jason.decode!()
           |> AST.decode()
  @parent_declarations [
                         %{
                           kind: "variable_declaration",
                           args: %{
                             label: "defined_elsewhere",
                             data_value: %{
                               kind: "point",
                               args: %{
                                 pointer_type: "GenericPointer",
                                 pointer_id: 123
                               }
                             }
                           }
                         }
                       ]
                       |> AST.decode()
  @default_declarations [
                          %{
                            kind: "parameter_declaration",
                            args: %{
                              label: "example_default",
                              default_value: %{
                                kind: "point",
                                args: %{
                                  pointer_type: "Plant",
                                  pointer_id: 456
                                }
                              }
                            }
                          },
                          # THIS SHOULD NOT GET APPLIED
                          %{
                            kind: "parameter_declaration",
                            args: %{
                              label: "var4",
                              default_value: %{
                                kind: "point",
                                args: %{
                                  pointer_type: "Plant",
                                  pointer_id: 555
                                }
                              }
                            }
                          }
                        ]
                        |> AST.decode()

  @too_many_groups [
                     %{
                       kind: "parameter_application",
                       args: %{
                         label: "first",
                         data_value: %{
                           kind: "point_group",
                           args: %{point_group_id: 31}
                         }
                       }
                     },
                     %{
                       kind: "parameter_application",
                       args: %{
                         label: "second",
                         data_value: %{
                           kind: "point_group",
                           args: %{point_group_id: 13}
                         }
                       }
                     }
                   ]
                   |> AST.decode()

  test "creation of a new scope" do
    prev = Scope.new(nil, @parent_declarations)
    expected = Enum.at(@parent_declarations, 0).args.data_value
    assert expected.kind == :point
    {:ok, actual} = Scope.fetch!(prev, "defined_elsewhere")
    assert expected == actual
    curr = Scope.new(prev, @fixture.body)
    {:ok, actual2} = Scope.fetch!(curr, "var3")
    assert expected == actual2
    with_defaults = Scope.apply_defaults(curr, @default_declarations)
    assert Scope.has_key?(with_defaults, "example_default")
    {:ok, default} = Scope.fetch!(with_defaults, "example_default")
    assert default == Enum.at(@default_declarations, 0).args.default_value
    {:ok, p} = Scope.fetch!(with_defaults, "var4")
    assert p.args.pointer_id == 444
  end

  test "prevent multiple iterables in the same scope" do
    t = fn -> Scope.new(nil, @too_many_groups) |> Scope.expand() end
    assert_raise RuntimeError, "You can only use one point group at a time.", t
  end

  test "crashes on bad variable names" do
    {:error, msg} = Scope.fetch!(Scope.new(), "wrong")

    assert msg ==
             "Attempted to access variable \"wrong\", but no variables are declared."
  end
end
