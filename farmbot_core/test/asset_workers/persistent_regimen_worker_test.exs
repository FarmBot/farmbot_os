defmodule FarmbotCore.PersistentRegimenWorkerTest do
  use ExUnit.Case, async: true

  alias FarmbotCeleryScript.Scheduler

  alias FarmbotCore.Asset.PersistentRegimen

  import Farmbot.TestSupport.AssetFixtures

  alias Farmbot.TestSupport.CeleryScript.TestSysCalls

  test "regimen executes a sequence" do
    now = DateTime.utc_now()
    start_time = Timex.shift(now, minutes: -20)
    end_time = Timex.shift(now, minutes: 10)
    {:ok, epoch} = PersistentRegimen.build_epoch(now)
    offset = Timex.diff(now, epoch, :milliseconds) + 500

    seq = sequence()
    regimen_params = %{regimen_items: [%{sequence_id: seq.id, time_offset: offset}]}

    farm_event_params = %{
      start_time: start_time,
      end_time: end_time,
      repeat: 1,
      time_unit: "never"
    }

    pr = persistent_regimen(regimen_params, farm_event_params)

    test_pid = self()

    args = [
      apply_sequence: fn _seq ->
        send(test_pid, :executed)
      end
    ]

    {:ok, _} = FarmbotCore.AssetWorker.FarmbotCore.Asset.PersistentRegimen.start_link(pr, args)
    assert_receive :executed
  end

  test "parameter_application" do
    now = DateTime.utc_now()
    start_time = Timex.shift(now, minutes: -20)
    end_time = Timex.shift(now, minutes: 10)
    {:ok, epoch} = PersistentRegimen.build_epoch(now)
    offset = Timex.diff(now, epoch, :milliseconds) + 500

    # Asset instances

    # Sequence that `execute`s another sequence
    # sequence that has move_abosolute to variable
    callee_sequence =
      sequence(%{
        args: %{
          locals: %{
            kind: "scope_declaration",
            args: %{},
            body: [
              %{
                kind: "parameter_declaration",
                args: %{
                  label: "callee_param",
                  default_value: %{
                    kind: "coordinate",
                    args: %{x: -1, y: -1, z: -1}
                  }
                }
              }
            ]
          }
        },
        body: [
          %{
            kind: "move_absolute",
            args: %{
              offset: %{
                kind: "coordinate",
                args: %{x: 0, y: 0, z: 0}
              },
              location: %{
                kind: "identifier",
                args: %{label: "callee_param"}
              }
            }
          }
        ]
      })

    caller_sequence =
      sequence(%{
        args: %{
          locals: %{
            kind: "scope_declaration",
            args: %{},
            body: [
              %{kind: "parameter_declaration",
              args: %{label: "provided_by_caller",
              default_value: %{
                kind: "coordinate",
                args: %{x: -2, y: -2, z: -2}
              }}}
            ]
          } 
        },
        body: [
          %{
            kind: "execute",
            args: %{sequence_id: callee_sequence.id},
            body: [
              %{
                kind: "parameter_application",
                args: %{
                  label: "callee_param",
                  data_value: %{
                    kind: "identifier",
                    args: %{label: "provided_by_caller"}
                  }
                }
              }
            ]
          }
        ]
      })

    # farm event that starts regimen
    # regimen that starts sequence
    regimen_params = %{
      regimen_items: [%{sequence_id: caller_sequence.id, time_offset: offset}],
      body: [
        %{
          kind: "parameter_application",
          args: %{
            label: "provided_by_caller",
            data_value: %{
              kind: "coordinate",
              args: %{
                x: 9000,
                y: 9000,
                z: 9000
              }
            }
          }
        }
      ]
    }

    farm_event_params = %{
      start_time: start_time,
      end_time: end_time,
      repeat: 1,
      time_unit: "never"
    }

    # process instances
    # inject syscalls
    # inject celery_script scheduler
    # inject apply_sequence to PersistentRegimen
    {:ok, shim} = TestSysCalls.checkout()
    that = self()

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        kind, args ->
          send(that, {kind, args})
      end)

    {:ok, sch} = Scheduler.start_link([], [])

    apply_sequence = fn sequence, regimen_body ->
      param_appls = FarmbotCeleryScript.AST.decode(regimen_body)
      env = FarmbotCeleryScript.Compiler.compile_params_to_function_args(param_appls)
      ast = FarmbotCeleryScript.AST.decode(sequence)
      IO.inspect(sch, label: "SCH")
      IO.inspect(ast, label: "AST")
      IO.inspect(env, label: "ENV")
      Scheduler.schedule(sch, ast, env)
      |> IO.inspect(label: "SCHEDULE/3")
    end

    pr = persistent_regimen(regimen_params, farm_event_params)

    args = [apply_sequence: apply_sequence]
    {:ok, _} = FarmbotCore.AssetWorker.FarmbotCore.Asset.PersistentRegimen.start_link(pr, args)

    expected_x = 9000
    expected_y = 9000
    expected_z = 9000
    assert_receive {:move_absolute, [^expected_x, ^expected_y, ^expected_z]}
  end
end
