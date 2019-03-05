defmodule FarmbotCore.BotState.FileSystemTest do
  use ExUnit.Case, async: false
  alias FarmbotCore.{BotState, BotState.FileSystem}

  describe "serializer" do
    test "arrays not aloud" do
      assert_raise RuntimeError, "Arrays can not be serialized to filesystem nodes", fn ->
        FileSystem.serialize_state(%{key: [:value, :nope]}, "/")
      end
    end

    test "serializes a map to the filesystem" do
      root_dir = Path.join([System.tmp_dir!(), Ecto.UUID.generate(), "-farmbot-map-serializer"])

      fixture = %{
        a_string: "hello",
        a_atom: :hello,
        a_int: 1,
        a_float: 1.0,
        a_bool: true,
        a_nil: nil,
        a_empty_map: %{},
        a_map: %{
          b_string: "world",
          b_atom: :world,
          b_int: 2,
          b_float: 2.0,
          b_bool: false,
          b_nil: nil,
          b_empty_map: %{}
        }
      }

      ser = FileSystem.serialize_state(fixture, root_dir)
      :ok = FileSystem.write_state(ser)

      assert File.read!(Path.join([root_dir, "a_string"])) == "hello"
      assert File.read!(Path.join([root_dir, "a_atom"])) == "hello"
      assert File.read!(Path.join([root_dir, "a_int"])) == "1"
      assert File.read!(Path.join([root_dir, "a_float"])) == "1.0"
      assert File.read!(Path.join([root_dir, "a_bool"])) == "true"
      assert File.read!(Path.join([root_dir, "a_nil"])) == ""
      assert File.dir?(Path.join([root_dir, "a_empty_map"]))

      assert File.read!(Path.join([root_dir, "a_map", "b_string"])) == "world"
      assert File.read!(Path.join([root_dir, "a_map", "b_atom"])) == "world"
      assert File.read!(Path.join([root_dir, "a_map", "b_int"])) == "2"
      assert File.read!(Path.join([root_dir, "a_map", "b_float"])) == "2.0"
      assert File.read!(Path.join([root_dir, "a_map", "b_bool"])) == "false"
      assert File.read!(Path.join([root_dir, "a_map", "b_nil"])) == ""
      assert File.dir?(Path.join([root_dir, "a_map", "b_empty_map"]))
    end
  end

  describe "server" do
    test "serializes state to fs" do
      root_dir = Path.join([System.tmp_dir!(), Ecto.UUID.generate(), "-farmbot-bot-state"])
      {:ok, bot_state_pid} = BotState.start_link([], [])

      {:ok, pid} =
        FileSystem.start_link(root_dir: root_dir, bot_state: bot_state_pid, sleep_time: 0)

      _ = BotState.subscribe(bot_state_pid)
      :ok = BotState.set_pin_value(bot_state_pid, 1, 1)
      assert_received {BotState, _}, 200
      # sleep to allow changes to propagate.
      Process.sleep(200)
      pins_dir = Path.join([root_dir, "pins", "1"])
      # default value
      assert File.read!(Path.join(pins_dir, "mode")) == "-1"
      assert File.read!(Path.join(pins_dir, "value")) == "1"
    end
  end
end
