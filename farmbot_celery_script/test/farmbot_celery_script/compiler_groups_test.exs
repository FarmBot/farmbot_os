defmodule FarmbotCeleryScript.CompilerGroupsTest do
  use ExUnit.Case, async: true
  alias FarmbotCeleryScript.AST
  alias Farmbot.TestSupport.CeleryScript.TestSysCalls
  # alias FarmbotCeleryScript.Compiler
  # # Only required to compile
  # alias FarmbotCeleryScript.SysCalls, warn: false
  # alias FarmbotCeleryScript.Compiler.IdentifierSanitizer

  setup do
    {:ok, shim} = TestSysCalls.checkout()

    [shim: shim]
  end

  test "compilation of point_group in parameter application", %{shim: shim} do
    main = %AST{
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
      body: [],
      comment: nil,
      kind: :sequence,
      meta: %{sequence_name: "Pogo"}
    }

    pid = self()
    fake_point_ids = [4, 5, 6, 7]

    :ok =
      TestSysCalls.handle(shim, fn kind, args ->
        case kind do
          :get_point_group ->
            send(pid, {kind, args})
            %{name: "woosh", point_ids: fake_point_ids}

          :step_complete ->
            send(pid, {kind, args})
            {:NOOO}

          :point ->
            %{name: "from the test suite %%", x: 6, y: 7, z: 8}
        end
      end)

    result = FarmbotCeleryScript.Compiler.Sequence.sequence(main, [])
    assert length(result) === 2 + length(fake_point_ids)
  end
end
