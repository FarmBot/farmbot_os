# defmodule FarmbotCore.FarmEventWorkerTest do
#   use ExUnit.Case, async: false
#   alias FarmbotCore.{Asset.FarmEvent, Asset.RegimenInstance, AssetWorker}
#   alias Farmbot.TestSupport.CeleryScript.TestSysCalls
#   import Farmbot.TestSupport.AssetFixtures

#   @farm_event_timeout_ms 10_000

#   # Regimen tests are in the RegimenInstanceWorker test

#   describe "sequences" do
#     test "passage of variables from FarmEvent to Sequence" do
#       # Create sequence with MoveABS that move to variable
#       sequence =
#         sequence(%{
#           args: %{
#             version: 0,
#             locals: %{
#               kind: "scope_declaration",
#               args: %{},
#               body: [
#                 %{
#                   kind: "parameter_declaration",
#                   args: %{
#                     label: "inside_sequence",
#                     default_value: %{
#                       kind: "coordinate",
#                       args: %{
#                         x: -1,
#                         y: -2,
#                         z: -3
#                       }
#                     }
#                   }
#                 }
#               ]
#             }
#           },
#           body: [
#             %{
#               kind: "move_absolute",
#               args: %{
#                 location: %{
#                   kind: "identifier",
#                   args: %{
#                     label: "inside_sequence"
#                   }
#                 },
#                 speed: 100,
#                 offset: %{
#                   kind: "coordinate",
#                   args: %{x: 0, y: 0, z: 0}
#                 }
#               }
#             }
#           ]
#         })

#       now = DateTime.utc_now()

#       params = %{
#         start_time: now,
#         end_time: Timex.shift(now, minutes: 10),
#         repeat: 1,
#         time_unit: "never",
#         body: [
#           %{
#             kind: "parameter_application",
#             args: %{
#               label: "inside_sequence",
#               data_value: %{
#                 kind: "coordinate",
#                 args: %{x: 9000, y: 9000, z: 9000}
#               }
#             }
#           }
#         ]
#       }

#       farm_event = sequence_event(sequence, params)
#       that = self()
#       {:ok, _} = TestSysCalls.checkout()

#       :ok =
#         TestSysCalls.handle(TestSysCalls, fn
#           :coordinate, [x, y, z] ->
#             %{x: x, y: y, z: z}

#           kind, args ->
#             send(that, {kind, args})
#             :ok
#         end)

#       {:ok, pid} = FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmEvent.start_link(farm_event, [])
#       assert_receive {:move_absolute, [9000, 9000, 9000, 100]}, @farm_event_timeout_ms
#     end

#     test "doesn't execute a sequence more than 2 mintues late" do
#       seq = sequence()
#       now = DateTime.utc_now()
#       start_time = Timex.shift(now, minutes: -20)
#       end_time = Timex.shift(now, minutes: 10)

#       params = %{
#         start_time: start_time,
#         end_time: end_time,
#         repeat: 1,
#         time_unit: "never"
#       }

#       assert %FarmEvent{} = fe = sequence_event(seq, params)
#       test_pid = self()

#       args = [
#         handle_sequence: fn _sequence, _event_body ->
#           send(test_pid, {:executed, test_pid})
#         end
#       ]

#       {:ok, _pid} = AssetWorker.start_link(fe, args)

#       # This is not really that useful.
#       refute_receive {:executed, ^test_pid}
#     end
#   end

#   describe "regimens" do
#     test "schedules a farmevent with body items to pass to a regimen to pass to a sequence" do
#       sequence =
#         sequence(%{
#           args: %{
#             locals: %{
#               kind: "scope_declaration",
#               args: %{},
#               body: [
#                 %{
#                   kind: "parameter_declaration",
#                   args: %{
#                     label: "from_regimen",
#                     default_value: %{
#                       kind: "coordinate",
#                       args: %{x: -1, y: -2, z: -3}
#                     }
#                   }
#                 }
#               ]
#             }
#           },
#           body: [
#             %{
#               kind: "move_absolute",
#               args: %{
#                 location: %{
#                   kind: "identifier",
#                   args: %{
#                     label: "from_regimen"
#                   }
#                 },
#                 offset: %{
#                   kind: "coordinate",
#                   args: %{x: 0, y: 0, z: 0}
#                 },
#                 speed: 100
#               }
#             }
#           ]
#         })

#       now = DateTime.utc_now()
#       {:ok, epoch} = RegimenInstance.build_epoch(now)
#       offset = Timex.diff(now, epoch, :milliseconds) + 500

#       regimen =
#         regimen(%{
#           regimen_items: [%{time_offset: offset, sequence_id: sequence.id}],
#           body: [
#             %{
#               kind: "parameter_declaration",
#               args: %{
#                 label: "from_regimen",
#                 default_value: %{
#                   kind: "coordinate",
#                   args: %{
#                     x: -5,
#                     y: -5,
#                     z: -5
#                   }
#                 }
#               }
#             }
#           ]
#         })

#       start_time = Timex.shift(now, minutes: -20)
#       end_time = Timex.shift(now, minutes: 10)

#       params = %{
#         start_time: start_time,
#         end_time: end_time,
#         repeat: 1,
#         time_unit: "never",
#         body: [
#           %{
#             kind: "parameter_application",
#             args: %{
#               label: "from_regimen",
#               data_value: %{
#                 kind: "coordinate",
#                 args: %{x: 8000, y: 8000, z: 8000}
#               }
#             }
#           }
#         ]
#       }

#       farm_event = regimen_event(regimen, params)

#       that = self()
#       {:ok, _} = TestSysCalls.checkout()

#       :ok =
#         TestSysCalls.handle(TestSysCalls, fn
#           :coordinate, [x, y, z] ->
#             %{x: x, y: y, z: z}

#           kind, args ->
#             send(that, {kind, args})
#             :ok
#         end)

#       {:ok, _} = FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmEvent.start_link(farm_event, [])
#       assert_receive {:move_absolute, [8000, 8000, 8000, 100]}, @farm_event_timeout_ms
#     end

#     test "Missing parameters, FarmEvent => Regimen => Sequence" do
#       sequence =
#         sequence(%{
#           args: %{
#             locals: %{
#               kind: "scope_declaration",
#               args: %{},
#               body: [
#                 %{
#                   kind: "parameter_declaration",
#                   args: %{
#                     label: "from_regimen",
#                     default_value: %{
#                       kind: "coordinate",
#                       args: %{x: -1, y: -2, z: -3}
#                     }
#                   }
#                 }
#               ]
#             }
#           },
#           body: [
#             %{
#               kind: "move_absolute",
#               args: %{
#                 location: %{
#                   kind: "identifier",
#                   args: %{
#                     label: "from_regimen"
#                   }
#                 },
#                 offset: %{
#                   kind: "coordinate",
#                   args: %{x: 0, y: 0, z: 0}
#                 },
#                 speed: 100
#               }
#             }
#           ]
#         })

#       now = DateTime.utc_now()
#       {:ok, epoch} = RegimenInstance.build_epoch(now)
#       offset = Timex.diff(now, epoch, :milliseconds) + 500

#       regimen =
#         regimen(%{
#           regimen_items: [%{time_offset: offset, sequence_id: sequence.id}],
#           body: []
#         })

#       start_time = Timex.shift(now, minutes: -20)
#       end_time = Timex.shift(now, minutes: 10)

#       params = %{
#         start_time: start_time,
#         end_time: end_time,
#         repeat: 1,
#         time_unit: "never",
#         body: []
#       }

#       farm_event = regimen_event(regimen, params)

#       that = self()
#       {:ok, _} = TestSysCalls.checkout()

#       :ok =
#         TestSysCalls.handle(TestSysCalls, fn
#           :coordinate, [x, y, z] ->
#             %{x: x, y: y, z: z}

#           kind, args ->
#             send(that, {kind, args})
#             :ok
#         end)

#       {:ok, _} = FarmbotCore.AssetWorker.FarmbotCore.Asset.FarmEvent.start_link(farm_event, [])
#       assert_receive {:move_absolute, [-1, -2, -3, 100]}, @farm_event_timeout_ms
#     end
#   end

#   describe "common" do
#     test "schedules an event in the future" do
#       seq = sequence(%{body: [%{kind: "read_pin", args: %{pin_number: 1, pin_mode: 0}}]})
#       now = DateTime.utc_now()
#       start_time = Timex.shift(now, milliseconds: 200)
#       end_time = Timex.shift(now, minutes: 10)

#       params = %{
#         start_time: start_time,
#         end_time: end_time,
#         repeat: 1,
#         time_unit: "minutely"
#       }

#       {:ok, _} = TestSysCalls.checkout()
#       test_pid = self()

#       assert %FarmEvent{} = fe = sequence_event(seq, params)

#       :ok =
#         TestSysCalls.handle(TestSysCalls, fn
#           kind, args ->
#             send(test_pid, {kind, args})
#             :ok
#         end)

#       {:ok, _pid} = AssetWorker.start_link(fe, [])
#       assert_receive {:read_pin, [1, 0]}, 10000
#     end

#     test "wont start an event after end_time" do
#       seq = sequence()
#       now = DateTime.utc_now()
#       start_time = Timex.shift(now, minutes: -12)
#       end_time = Timex.shift(now, minutes: -10)
#       assert Timex.from_now(end_time) == "10 minutes ago"

#       params = %{
#         start_time: start_time,
#         end_time: end_time,
#         repeat: 1,
#         time_unit: "minutely"
#       }

#       assert %FarmEvent{} = fe = sequence_event(seq, params)
#       # refute FarmEvent.build_calendar(fe, now)
#       assert fe.end_time == end_time
#       test_pid = self()

#       args = [
#         handle_sequence: fn _sequence, _event_body ->
#           send(test_pid, {:executed, test_pid})
#         end
#       ]

#       assert {:ok, _pid} = AssetWorker.start_link(fe, args)
#       # This is not really that useful.
#       refute_receive {:executed, ^test_pid}, @farm_event_timeout_ms
#     end
#   end
# end
