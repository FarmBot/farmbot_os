defmodule FarmbotCeleryScript.MoveCompilerTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotCeleryScript.{
    Compiler,
    SysCalls.Stubs
  }

  alias FarmbotCeleryScript.SysCalls, warn: false

  setup :verify_on_exit!

  @safe_height %{args: %{label: "safe_height"}, kind: :special_value}
  @soil_height %{args: %{label: "soil_height"}, kind: :special_value}
  @current_location %{
    kind: :special_value,
    args: %{label: "current_location"}
  }
  @fake_movment_needs %{
    safe_z: false,
    speed_x: 99,
    speed_y: 98,
    speed_z: 97,
    x: -4,
    y: -3,
    z: -2
  }

  test "MOVE + `tool` node" do
    stub_current_location(1)
    {toolX, toolY, toolZ} = {37.3, 43.7, -34.3}

    expect(Stubs, :get_toolslot_for_tool, 3, fn
      23 -> %{gantry_mounted: false, name: "X", x: toolX, y: toolY, z: toolZ}
      id -> raise "Wrong id: #{id}"
    end)

    expect(Stubs, :move_absolute, 1, fn requested_x,
                                        requested_y,
                                        requested_z,
                                        _,
                                        _,
                                        _ ->
      assert requested_x == toolX
      assert requested_y == toolY
      assert requested_z == toolZ

      :ok
    end)

    tool = %{kind: :tool, args: %{tool_id: 23}}

    body = [
      %{kind: :axis_overwrite, args: %{axis: "x", axis_operand: tool}},
      %{kind: :axis_overwrite, args: %{axis: "y", axis_operand: tool}},
      %{kind: :axis_overwrite, args: %{axis: "z", axis_operand: tool}}
    ]

    Compiler.Move.perform_movement(body, %{})
  end

  test "extract_variables" do
    body = [
      %{args: %{axis_operand: %{args: %{label: "q"}, kind: :identifier}}},
      :something_else
    ]

    better_params = %{"q" => %{foo: :bar}}
    result = Compiler.Move.extract_variables(body, better_params)

    assert result == [
             %{args: %{axis_operand: %{foo: :bar}}},
             :something_else
           ]
  end

  test "do_perform_movement(%{safe_z: true})" do
    stub_current_location(2)
    Stubs.get_current_z()

    expect(Stubs, :move_absolute, 3, fn _, _, _, _, _, _ ->
      :ok
    end)

    needs = Map.merge(@fake_movment_needs, %{safe_z: true})
    Compiler.Move.do_perform_movement(needs)
  end

  test "do_perform_movement(%{safe_z: false})" do
    expect(Stubs, :move_absolute, 1, fn _, _, _, _, _, _ ->
      :ok
    end)

    Compiler.Move.do_perform_movement(@fake_movment_needs)
  end

  test "retract_z" do
    {x, y, _z} = stub_current_location(1)
    # Used by helper stub_current_location, but not needed here.
    _ = Stubs.get_current_z()

    mock = fn real_x, real_y, real_z, sx, sy, sz ->
      assert real_x == x
      assert real_y == y
      assert real_z == 0
      assert @fake_movment_needs[:speed_x] == sx
      assert @fake_movment_needs[:speed_y] == sy
      assert @fake_movment_needs[:speed_z] == sz
      :ok
    end

    expect(Stubs, :move_absolute, mock)
    Compiler.Move.retract_z(@fake_movment_needs)
  end

  test "move_xy" do
    {_x, _y, z} = stub_current_location(1)
    # Used by helper stub_current_location, but not needed here.
    _ = Stubs.get_current_x()
    # Used by helper stub_current_location, but not needed here.
    _ = Stubs.get_current_y()

    mock = fn real_x, real_y, real_z, sx, sy, sz ->
      assert real_x == @fake_movment_needs[:x]
      assert real_y == @fake_movment_needs[:y]
      assert real_z == z
      assert @fake_movment_needs[:speed_x] == sx
      assert @fake_movment_needs[:speed_y] == sy
      assert @fake_movment_needs[:speed_z] == sz
      :ok
    end

    expect(Stubs, :move_absolute, mock)
    Compiler.Move.move_xy(@fake_movment_needs)
  end

  test "extend_z" do
    {x, y, _z} = stub_current_location(1)
    # Used by helper stub_current_location, but not needed here.
    _ = Stubs.get_current_z()

    mock = fn real_x, real_y, real_z, sx, sy, sz ->
      assert real_x == x
      assert real_y == y
      assert real_z == @fake_movment_needs[:z]
      assert @fake_movment_needs[:speed_x] == sx
      assert @fake_movment_needs[:speed_y] == sy
      assert @fake_movment_needs[:speed_z] == sz
      :ok
    end

    expect(Stubs, :move_absolute, mock)
    Compiler.Move.extend_z(@fake_movment_needs)
  end

  test "calculate_movement_needs" do
    {x, y, z} = stub_current_location(1)

    assert Compiler.Move.calculate_movement_needs([]) == %{
             safe_z: false,
             speed_x: 100,
             speed_y: 100,
             speed_z: 100,
             x: x,
             y: y,
             z: z
           }
  end

  test "reducer" do
    needs = %{speed_x: 23, y: 32}
    result1 = Compiler.Move.reducer({:speed_x, :=, 44}, needs)
    result2 = Compiler.Move.reducer({:y, :+, 32}, needs)
    assert result1[:speed_x] == 44
    assert result2[:y] == 64
  end

  test "mapper" do
    numeric = %{kind: :numeric, args: %{number: 26}}
    safe_z = %{kind: :safe_z, args: %{}}

    axis_addition = %{
      kind: :axis_addition,
      args: %{axis: "y", axis_operand: numeric}
    }

    speed_overwrite = %{
      kind: :speed_overwrite,
      args: %{axis: "x", speed_setting: numeric}
    }

    axis_overwrite = %{
      kind: :axis_overwrite,
      args: %{axis: "z", axis_operand: numeric}
    }

    assert Compiler.Move.mapper(safe_z) == {:safe_z, :=, true}
    assert Compiler.Move.mapper(speed_overwrite) == {:speed_x, :=, 26}
    assert Compiler.Move.mapper(axis_addition) == {:y, :+, 26}
    assert Compiler.Move.mapper(axis_overwrite) == {:z, :=, 26}

    boom = fn ->
      Compiler.Move.mapper(%{
        kind: :axis_addition,
        args: %{
          axis: "all",
          axis_operand: numeric
        }
      })
    end

    assert_raise RuntimeError, "Not permitted", boom
  end

  # test "to_number() - Lua" do
  #   expect(Stubs, :perform_lua, 3, fn
  #     "lol", _, _ ->
  #       "Something else"

  #     lua, _, _ ->
  #       {result, _} = Code.eval_string(lua)
  #       {:ok, [result]}
  #   end)

  #   # Base case: Returns {:ok, [number]}
  #   # lua1 = %{kind: :lua, args: %{lua: "2 + 2"}}
  #   # Compiler.Move.to_number(:x, lua1)

  #   # Error case: Returns {:ok, [not_a_number]}
  #   # lua2 = %{kind: :lua, args: %{lua: "\"Not a number\""}}
  #   # boom = fn -> Compiler.Move.to_number(:x, lua2) end
  #   # err_msg = "Unexpected Lua return: \"Not a number\" \"\\\"Not a number\\\"\""
  #   # assert_raise RuntimeError, err_msg, boom

  #   # Error case: Returns some other shape of data.
  #   # lua3 = %{kind: :lua, args: %{lua: "lol"}}
  #   # boom = fn -> Compiler.Move.to_number(:x, lua3) end
  #   # err_msg = "Unexpected Lua return: \"Something else\" \"lol\""
  #   # assert_raise RuntimeError, err_msg, boom
  # end

  test "to_number()" do
    boom = fn -> Compiler.Move.to_number(:foo, :bar) end
    err_msg = "Can't handle numeric conversion for :bar"
    assert_raise RuntimeError, err_msg, boom
    {x, y, z} = stub_current_location(3)
    vec = %{x: x, y: y, z: z}
    fake_numeric = %{args: %{number: 101}, kind: :numeric}

    fake_pointer = %{
      kind: :point,
      args: %{pointer_id: 1, pointer_type: "GenericPointer"}
    }

    fake_resource = %{resource_id: 1, resource_type: "GenericPointer"}

    expect(Stubs, :point, 6, fn t, id ->
      %{
        name: "untitled",
        resource_id: id,
        resource_type: t,
        x: 776.0,
        y: 633.0,
        z: 5.0
      }
    end)

    fake_coordinate = %{
      kind: :coordinate,
      args: %{x: 202, y: 404, z: 808}
    }

    fake_variance = %{kind: :random, args: %{variance: 10}}

    expect(FarmbotCeleryScript.SpecialValue, :safe_height, fn -> 1.23 end)
    expect(FarmbotCeleryScript.SpecialValue, :soil_height, fn -> 3.45 end)

    assert Compiler.Move.to_number(:z, @soil_height) == 3.45
    assert Compiler.Move.to_number(:z, @safe_height) == 1.23
    assert Compiler.Move.to_number(:x, vec) == x
    assert Compiler.Move.to_number(:y, vec) == y
    assert Compiler.Move.to_number(:z, vec) == z
    assert Compiler.Move.to_number(:x, @current_location) == x
    assert Compiler.Move.to_number(:y, @current_location) == y
    assert Compiler.Move.to_number(:z, @current_location) == z
    assert Compiler.Move.to_number(:x, fake_pointer) == 776.0
    assert Compiler.Move.to_number(:x, fake_resource) == 776.0
    assert Compiler.Move.to_number(:y, fake_pointer) == 633.0
    assert Compiler.Move.to_number(:y, fake_resource) == 633.0
    assert Compiler.Move.to_number(:z, fake_pointer) == 5.0
    assert Compiler.Move.to_number(:z, fake_resource) == 5.0
    assert Compiler.Move.to_number(:z, fake_numeric) == 101
    assert Compiler.Move.to_number(:y, fake_coordinate) == 404
    v = Compiler.Move.to_number(:y, fake_variance)
    assert v <= 10
    assert v >= -10
  end

  test "cx(), cy(), cz(), initial_state()" do
    {x, y, z} = stub_current_location(2)
    state = Compiler.Move.initial_state()
    assert(Compiler.Move.cx() == x)
    assert(Compiler.Move.cy() == y)
    assert(Compiler.Move.cz() == z)
    assert Enum.member?(state, {:x, :=, x})
    assert Enum.member?(state, {:y, :=, y})
    assert Enum.member?(state, {:z, :=, z})
    assert Enum.member?(state, {:speed_x, :=, 100})
    assert Enum.member?(state, {:speed_y, :=, 100})
    assert Enum.member?(state, {:speed_z, :=, 100})
    assert Enum.member?(state, {:safe_z, :=, false})
  end

  test "move_abs()" do
    params = %{
      x: rand_coord(),
      y: rand_coord(),
      z: rand_coord(),
      speed_x: 2,
      speed_y: 2,
      speed_z: 2
    }

    mock = fn x, y, z, sx, sy, sz ->
      assert params[:x] == x
      assert params[:y] == y
      assert params[:z] == z
      assert params[:speed_x] == sx
      assert params[:speed_y] == sy
      assert params[:speed_z] == sz
      :ok
    end

    expect(Stubs, :move_absolute, mock)
    Compiler.Move.move_abs(params)
  end

  defp rand_coord(), do: trunc(:rand.uniform() * 1000)

  defp stub_current_location(call_count) do
    x = rand_coord()
    y = rand_coord()
    z = rand_coord()

    expect(Stubs, :get_current_x, call_count, fn -> x end)
    expect(Stubs, :get_current_y, call_count, fn -> y end)
    expect(Stubs, :get_current_z, call_count, fn -> z end)

    {x, y, z}
  end
end
