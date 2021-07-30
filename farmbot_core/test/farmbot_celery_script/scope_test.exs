defmodule FarmbotCeleryScript.Compiler.ScopeTest do
  use ExUnit.Case
  alias FarmbotCeleryScript.AST
  alias FarmbotCeleryScript.Compiler.Scope

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
    assert expected == Scope.fetch!(prev, "defined_elsewhere")
    curr = Scope.new(prev, @fixture.body)
    assert expected == Scope.fetch!(curr, "var3")
    with_defaults = Scope.apply_defaults(curr, @default_declarations)
    assert Scope.has_key?(with_defaults, "example_default")
    default = Scope.fetch!(with_defaults, "example_default")
    assert default == Enum.at(@default_declarations, 0).args.default_value
    assert Scope.fetch!(with_defaults, "var4").args.pointer_id == 444
  end

  # test "expansion of a single point_group node" do
  #   "farmbot_core/fixture/point_group_sequence.json"
  # end

  test "prevent multiple iterables in the same scope" do
    t = fn -> Scope.new(nil, @too_many_groups) |> Scope.expand() end
    assert_raise RuntimeError, "You can only use one point group at a time.", t
  end
end
