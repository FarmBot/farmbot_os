defmodule FarmbotCore.RegimenInstanceWorkerTest do
  use ExUnit.Case, async: false

  alias FarmbotCeleryScript.Scheduler

  alias FarmbotCore.Asset.RegimenInstance

  import Farmbot.TestSupport.AssetFixtures

  alias Farmbot.TestSupport.CeleryScript.TestSysCalls

  test "regimen executes a sequence" do
    now = DateTime.utc_now()
    start_time = Timex.shift(now, minutes: -20)
    end_time = Timex.shift(now, minutes: 10)
    {:ok, epoch} = RegimenInstance.build_epoch(now)
    offset = Timex.diff(now, epoch, :milliseconds) + 500

    seq = sequence()
    regimen_params = %{regimen_items: [%{sequence_id: seq.id, time_offset: offset}]}

    farm_event_params = %{
      start_time: start_time,
      end_time: end_time,
      repeat: 1,
      time_unit: "never"
    }

    pr = regimen_instance(regimen_params, farm_event_params)

    test_pid = self()

    args = [
      apply_sequence: fn _seq, _body_args ->
        send(test_pid, :executed)
      end
    ]

    {:ok, _} = FarmbotCore.AssetWorker.FarmbotCore.Asset.RegimenInstance.start_link(pr, args)
    assert_receive :executed
  end

  test "parameter_application" do
    now = DateTime.utc_now()
    start_time = Timex.shift(now, minutes: -20)
    end_time = Timex.shift(now, minutes: 10)
    {:ok, epoch} = RegimenInstance.build_epoch(now)
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
              speed: 100,
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
              %{
                kind: "parameter_declaration",
                args: %{
                  label: "provided_by_caller",
                  default_value: %{
                    kind: "coordinate",
                    args: %{x: -2, y: -2, z: -2}
                  }
                }
              }
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
    # inject apply_sequence to RegimenInstance
    {:ok, shim} = TestSysCalls.checkout()
    that = self()

    callee_sequence_id = callee_sequence.id

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :get_sequence, [^callee_sequence_id] ->
          FarmbotCeleryScript.AST.decode(callee_sequence)

        :coordinate, [x, y, z] ->
          %{x: x, y: y, z: z}

        kind, args ->
          send(that, {kind, args})
          :ok
      end)

    pr = regimen_instance(regimen_params, farm_event_params)

    {:ok, _} = FarmbotCore.AssetWorker.FarmbotCore.Asset.RegimenInstance.start_link(pr, [])

    expected_x = 9000
    expected_y = 9000
    expected_z = 9000
    expected_speed = 100

    assert_receive {:move_absolute, [^expected_x, ^expected_y, ^expected_z, ^expected_speed]}
  end

  test "application of default_parameters (Regimen => Sequence)" do
    now = DateTime.utc_now()
    start_time = Timex.shift(now, minutes: -20)
    end_time = Timex.shift(now, minutes: 10)
    {:ok, epoch} = RegimenInstance.build_epoch(now)
    offset = Timex.diff(now, epoch, :milliseconds) + 500

    # Asset instances

    # Sequence that `execute`s another sequence
    # sequence that has move_abosolute to variable
    the_sequence =
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
              speed: 100,
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

    regimen_params = %{
      regimen_items: [%{sequence_id: the_sequence.id, time_offset: offset}],
      body: []
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
    # inject apply_sequence to RegimenInstance
    {:ok, shim} = TestSysCalls.checkout()
    that = self()

    the_sequence_id = the_sequence.id

    :ok =
      TestSysCalls.handle(TestSysCalls, fn
        :coordinate, [x, y, z] ->
          %{x: x, y: y, z: z}

        kind, args ->
          send(that, {kind, args})
          :ok
      end)

    pr = regimen_instance(regimen_params, farm_event_params)

    {:ok, _} = FarmbotCore.AssetWorker.FarmbotCore.Asset.RegimenInstance.start_link(pr, [])

    expected_x = -1
    expected_y = -1
    expected_z = -1
    expected_speed = 100

    assert_receive {:move_absolute, [^expected_x, ^expected_y, ^expected_z, ^expected_speed]},
                   5_000
  end
end
