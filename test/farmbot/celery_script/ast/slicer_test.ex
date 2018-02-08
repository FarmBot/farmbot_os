defmodule AST.SlicerTest do
  use ExUnit.Case
  alias Farmbot.CeleryScript.AST
  alias AST.{Heap, Slicer}
  alias AST.Heap.Address

  @big_real_sequence %AST{
    kind: AST.Node.Sequence,
    args: %{
      is_outdated: false,
      locals: %{args: %{}, kind: "scope_declaration"},
      version: 6
    },
    body: [
      %AST{
        args: %{
          location: %{args: %{x: 1, y: 2, z: 3}, kind: "coordinate"},
          offset: %{args: %{x: 0, y: 0, z: 0}, kind: "coordinate"},
          speed: 4
        },
        body: [],
        kind: AST.Node.MoveAbsolute
      },
      %AST{
        args: %{
          location: %{args: %{tool_id: 1}, kind: "tool"},
          offset: %{args: %{x: 0, y: 0, z: 0}, kind: "coordinate"},
          speed: 4
        },
        body: [],
        kind: AST.Node.MoveAbsolute
      },
      %AST{
        args: %{speed: 4, x: 1, y: 2, z: 3},
        body: [],
        kind: AST.Node.MoveRelative
      },
      %AST{
        args: %{pin_mode: 1, pin_number: 1, pin_value: 128},
        body: [],
        kind: AST.Node.WritePin
      },
      %AST{
        args: %{label: "my_pin", pin_mode: 1, pin_number: 1},
        body: [],
        kind: AST.Node.ReadPin
      },
      %AST{
        args: %{milliseconds: 500},
        body: [],
        kind: AST.Node.Wait
      },
      %AST{
        args: %{
          message: "Bot at coord {{ x }} {{ y }} {{ z }}.",
          message_type: "info"
        },
        body: [
          %AST{
            args: %{channel_name: "toast"},
            body: [],
            kind: AST.Node.Channel
          }
        ],
        kind: AST.Node.SendMessage
      },
      %AST{
        args: %{
          _else: %{args: %{}, kind: "nothing"},
          _then: %{args: %{sequence_id: 1}, kind: "execute"},
          lhs: "x",
          op: "is",
          rhs: 300
        },
        body: [],
        kind: AST.Node.If
      },
      %AST{
        args: %{sequence_id: 1},
        body: [],
        kind: AST.Node.Execute
      }
    ]
  }

  @unrealistic_but_valid_sequence %AST{
    kind: AST.Node.ROOT,
    args: %{a: "b"},
    body: [
      %AST{
        kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[0]",
        args: %{c: "d"},
        body: [
          %AST{
            kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[0][0]",
            args: %{e: "f"},
            body: []
          }
        ]
      },
      %AST{
        args: %{c: "d"},
        body: [
          %AST{
            args: %{g: "H"},
            body: [],
            kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[1][0]"
          },
          %AST{
            args: %{i: "j"},
            body: [],
            kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[1][1]"
          },
          %AST{
            args: %{k: "l"},
            body: [],
            kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[1][2]"
          }
        ],
        kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[1]"
      },
      %AST{
        args: %{c: "d"},
        body: [
          %AST{
            args: %{m: "n"},
            body: [],
            kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][0]"
          },
          %AST{
            args: %{o: "p"},
            body: [],
            kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][1]"
          },
          %AST{
            kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][2]",
            args: %{
              q: "1",
              z: %AST{
                kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][-1]",
                args: %{},
                body: []
              }
            },
            body: [
              %AST{
                args: %{g: "H"},
                body: [],
                kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][2][0]"
              }
            ]
          }
        ],
        kind: :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2]"
      }
    ]
  }

  @parent Heap.parent()
  @kind Heap.kind()
  @body Heap.body()
  @next Heap.next()

  test "Slices a realistic sequence" do
    Slicer.run(@big_real_sequence)
    # TODO Actually check this?
  end

  @tag timeout: :infinity
  test "Slices an unrealistic_but_valid_sequence" do
    heap = Slicer.run(@unrealistic_but_valid_sequence)
    assert Enum.count(heap.entries) == 14
    assert heap.here == Address.new(13)

    assert heap[addr(1)][@kind]                == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT"
    assert heap[heap[addr(1)][@body]][@kind]   == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[0]"
    assert heap[heap[addr(1)][@next]][@kind]   == Farmbot.CeleryScript.AST.Node.Nothing
    assert heap[heap[addr(1)][@parent]][@kind] == Farmbot.CeleryScript.AST.Node.Nothing

    assert heap[addr(2)][@kind]                == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[0]"
    assert heap[heap[addr(2)][@body]][@kind]   == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[0][0]"
    assert heap[heap[addr(2)][@next]][@kind]   == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[1]"
    assert heap[heap[addr(2)][@parent]][@kind] == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT"

    # AST with more ast in the args and asts in the body
    assert heap[addr(11)][@kind] == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][2]"
    assert heap[heap[addr(11)][@body]][@kind]   == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][2][0]"
    assert heap[heap[addr(11)][@next]][@kind]   == Farmbot.CeleryScript.AST.Node.Nothing
    assert heap[heap[addr(11)][@parent]][@kind] == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][1]"

    assert heap[addr(12)][@kind] == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][2][0]"
    assert heap[heap[addr(12)][@body]][@kind]   == Farmbot.CeleryScript.AST.Node.Nothing
    assert heap[heap[addr(12)][@next]][@kind]   == Farmbot.CeleryScript.AST.Node.Nothing
    assert heap[heap[addr(12)][@parent]][@kind] == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][2]"

    assert heap[addr(13)][@kind] == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][-1]"
    assert heap[heap[addr(13)][@body]][@kind]   == Farmbot.CeleryScript.AST.Node.Nothing
    assert heap[heap[addr(13)][@next]][@kind]   == Farmbot.CeleryScript.AST.Node.Nothing
    assert heap[heap[addr(13)][@parent]][@kind] == :"Elixir.Farmbot.CeleryScript.AST.Node.ROOT[2][2]"
  end

  defp addr(num), do: Address.new(num)
end
