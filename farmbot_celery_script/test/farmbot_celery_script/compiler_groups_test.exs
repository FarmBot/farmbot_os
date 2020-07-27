defmodule FarmbotCeleryScript.CompilerGroupsTest do
  use ExUnit.Case, async: true
  use Mimic

  alias FarmbotCeleryScript.AST
  alias FarmbotCeleryScript.SysCalls.Stubs
  alias FarmbotCeleryScript.Compiler.Sequence
  setup :verify_on_exit!

  test "compilation of point_group in parameter application" do
    fake_point_ids = [4, 5, 6, 7]

    expect(Stubs, :find_points_via_group, fn _ ->
      %{name: "woosh", point_ids: fake_point_ids}
    end)

    expect(Stubs, :point, 4, fn _kind, id ->
      # EDGE CASE: Handle malformed stuff by ensuring that 50% of
      #            points have no name.

      if rem(id, 2) == 0 do
        %{name: "from the test suite %%", x: 6, y: 7, z: 8}
      else
        %{x: 6, y: 7, z: 8}
      end
    end)

    result = Sequence.sequence(fake_ast(), [])

    length1 = 2 + length(fake_point_ids)
    length2 = length(result)
    assert length2 === length1
    # ============================================
    # ABOUT THIS (brittle) TEST:
    # You should not write tests like this and
    # there is a high liklihood that the code below
    # will break in the future.
    # This is especially true if you intend to change
    # the behavior of Sequence.sequence/2.
    # If you WERE NOT EXPECTING to change the behavior
    # of Sequence.sequence/2 and this test fails,
    # you should consider it a true failure that
    # requires investigation.
    # IT IS OK TO REPLACE THIS TEST WITH BETTER
    # TESTS.
    # ============================================
    canary_actual = :crypto.hash(:sha, Macro.to_string(result))

    canary_expected =
      <<236, 29, 24, 25, 105, 25, 68, 38, 103, 59, 239, 52, 253, 232, 185, 173,
        242, 196, 109, 82>>

    # READ THE NOTE ABOVE IF THIS TEST FAILS!!!
    assert canary_expected == canary_actual
  end

  defp fake_ast() do
    %AST{
      args: %{
        locals: %AST{
          args: %{},
          body: [
            %AST{
              args: %{
                default_value: %AST{
                  args: %{pointer_id: 1670, pointer_type: "Plant"},
                  body: [],
                  comment: nil,
                  kind: :point,
                  meta: nil
                },
                label: "parent"
              },
              body: [],
              comment: nil,
              kind: :parameter_declaration,
              meta: nil
            },
            %AST{
              args: %{
                data_value: %AST{
                  args: %{point_group_id: 34},
                  body: [],
                  comment: nil,
                  kind: :point_group,
                  meta: nil
                },
                label: "parent"
              },
              body: [],
              comment: nil,
              kind: :parameter_application,
              meta: nil
            }
          ],
          comment: nil,
          kind: :scope_declaration,
          meta: nil
        },
        sequence_name: "Pogo",
        version: 20_180_209
      },
      body: [
        %AST{
          kind: :move_absolute,
          args: %{
            speed: 100,
            location: %AST{kind: :identifier, args: %{label: "parent"}},
            offset: %AST{
              kind: :coordinate,
              args: %{x: -20, y: -20, z: -20}
            }
          },
          body: []
        }
      ],
      comment: nil,
      kind: :sequence,
      meta: %{sequence_name: "Pogo"}
    }
  end
end
