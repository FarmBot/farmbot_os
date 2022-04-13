defmodule FarmbotOS.Celery.MoveCompilerTest do
  use ExUnit.Case, async: false
  use Mimic

  alias FarmbotOS.Celery.{
    Compiler,
    Compiler.Move,
    SysCallGlue.Stubs
  }

  # alias FarmbotOS.Celery.SysCallGlue

  setup :verify_on_exit!

  @safe_height %{args: %{label: "safe_height"}, kind: :special_value}
  @soil_height %{args: %{label: "soil_height"}, kind: :special_value}
  @current_location %{
    kind: :special_value,
    args: %{label: "current_location"}
  }
  @fake_movement_needs %{
    safe_z: false,
    speed_x: 99,
    speed_y: 98,
    speed_z: 97,
    x: -4,
    y: -3,
    z: -2
  }

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

    Move.perform_movement(body, %{})
  end

  test "extract_variables" do
    body = [
      %{args: %{axis_operand: %{args: %{label: "q"}, kind: :identifier}}},
      :something_else
    ]

    cs_scope = %{declarations: %{"q" => %{foo: :bar}}}
    result = Move.extract_variables(body, cs_scope)

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

    needs = Map.merge(@fake_movement_needs, %{safe_z: true})
    Move.do_perform_movement(needs)
  end

  test "do_perform_movement(%{safe_z: false})" do
    expect(Stubs, :move_absolute, 1, fn _, _, _, _, _, _ ->
      :ok
    end)

    Move.do_perform_movement(@fake_movement_needs)
  end

  test "retract_z" do
    {x, y, _z} = stub_current_location(1)
    # Used by helper stub_current_location, but not needed here.
    _ = Stubs.get_current_z()

    mock = fn real_x, real_y, real_z, sx, sy, sz ->
      assert real_x == x
      assert real_y == y
      assert real_z == 0
      assert @fake_movement_needs[:speed_x] == sx
      assert @fake_movement_needs[:speed_y] == sy
      assert @fake_movement_needs[:speed_z] == sz
      :ok
    end

    expect(Stubs, :move_absolute, mock)
    Move.retract_z(@fake_movement_needs)
  end

  test "move_xy" do
    {_x, _y, z} = stub_current_location(1)
    # Used by helper stub_current_location, but not needed here.
    _ = Stubs.get_current_x()
    # Used by helper stub_current_location, but not needed here.
    _ = Stubs.get_current_y()

    mock = fn real_x, real_y, real_z, sx, sy, sz ->
      assert real_x == @fake_movement_needs[:x]
      assert real_y == @fake_movement_needs[:y]
      assert real_z == z
      assert @fake_movement_needs[:speed_x] == sx
      assert @fake_movement_needs[:speed_y] == sy
      assert @fake_movement_needs[:speed_z] == sz
      :ok
    end

    expect(Stubs, :move_absolute, mock)
    Move.move_xy(@fake_movement_needs)
  end

  test "extend_z" do
    {x, y, _z} = stub_current_location(1)
    # Used by helper stub_current_location, but not needed here.
    _ = Stubs.get_current_z()

    mock = fn real_x, real_y, real_z, sx, sy, sz ->
      assert real_x == x
      assert real_y == y
      assert real_z == @fake_movement_needs[:z]
      assert @fake_movement_needs[:speed_x] == sx
      assert @fake_movement_needs[:speed_y] == sy
      assert @fake_movement_needs[:speed_z] == sz
      :ok
    end

    expect(Stubs, :move_absolute, mock)
    Move.extend_z(@fake_movement_needs)
  end

  test "calculate_movement_needs" do
    {x, y, z} = stub_current_location(1)

    assert Move.calculate_movement_needs([]) == %{
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
    result1 = Move.reducer({:speed_x, :=, 44}, needs)
    result2 = Move.reducer({:y, :+, 32}, needs)
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

    assert Move.mapper(safe_z) == {:safe_z, :=, true}
    assert Move.mapper(speed_overwrite) == {:speed_x, :=, 26}
    assert Move.mapper(axis_addition) == {:y, :+, 26}
    assert Move.mapper(axis_overwrite) == {:z, :=, 26}

    boom = fn ->
      Move.mapper(%{
        kind: :axis_addition,
        args: %{
          axis: "all",
          axis_operand: numeric
        }
      })
    end

    assert_raise RuntimeError, "Not permitted", boom
  end

  test "to_number()" do
    boom = fn -> Move.to_number(:foo, :bar) end
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

    expect(FarmbotOS.Celery.SpecialValue, :safe_height, fn -> 1.23 end)

    assert Move.to_number(:z, @soil_height) == {:skip, :soil_height}
    assert Move.to_number(:z, @safe_height) == 1.23
    assert Move.to_number(:x, vec) == x
    assert Move.to_number(:y, vec) == y
    assert Move.to_number(:z, vec) == z
    assert Move.to_number(:x, @current_location) == x
    assert Move.to_number(:y, @current_location) == y
    assert Move.to_number(:z, @current_location) == z
    assert Move.to_number(:x, fake_pointer) == 776.0
    assert Move.to_number(:x, fake_resource) == 776.0
    assert Move.to_number(:y, fake_pointer) == 633.0
    assert Move.to_number(:y, fake_resource) == 633.0
    assert Move.to_number(:z, fake_pointer) == 5.0
    assert Move.to_number(:z, fake_resource) == 5.0
    assert Move.to_number(:z, fake_numeric) == 101
    assert Move.to_number(:y, fake_coordinate) == 404
    v = Move.to_number(:y, fake_variance)
    assert v <= 10
    assert v >= -10
  end

  test "cx(), cy(), cz(), initial_state()" do
    {x, y, z} = stub_current_location(2)
    state = Move.initial_state()
    assert(Move.cx() == x)
    assert(Move.cy() == y)
    assert(Move.cz() == z)
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
    Move.move_abs(params)
  end

  test "preprocess_lua" do
    expect(Compiler.Lua, :do_lua, 4, fn lua, _ ->
      {res, _} = Code.eval_string(lua)
      {:ok, [res]}
    end)

    results =
      Move.preprocess_lua(
        [
          %{kind: :test, args: %{speed_setting: %{args: %{lua: "2+2"}}}},
          %{kind: :test, args: %{speed_setting: %{args: %{lua: "8+8"}}}},
          %{kind: :nothing, args: %{}},
          %{kind: :test, args: %{lua: "4+4"}},
          %{kind: :test, args: %{axis_operand: %{args: %{lua: "1+2"}}}}
        ],
        %{}
      )

    assert Enum.at(results, 0) == %{
             kind: :test,
             args: %{speed_setting: %{args: %{number: 4}, kind: :numeric}}
           }

    assert Enum.at(results, 1) == %{
             kind: :test,
             args: %{speed_setting: %{args: %{number: 16}, kind: :numeric}}
           }

    assert Enum.at(results, 2) == %{args: %{}, kind: :nothing}

    assert Enum.at(results, 3) == %{
             kind: :test,
             args: %{args: %{number: 8}, kind: :numeric}
           }

    assert Enum.at(results, 4) == %{
             kind: :test,
             args: %{axis_operand: %{args: %{number: 3}, kind: :numeric}}
           }
  end

  test "convert_lua_to_number" do
    expect(Compiler.Lua, :do_lua, 2, fn
      "example1()", _ ->
        {:ok, [false]}

      "example2()", _ ->
        "random error"
    end)

    test1 = fn -> Move.convert_lua_to_number("example1()", %{}) end
    test2 = fn -> Move.convert_lua_to_number("example2()", %{}) end

    assert_raise RuntimeError,
                 "Expected Lua to return number, got false. \"example1()\"",
                 test1

    assert_raise RuntimeError,
                 "Expected Lua to return number, got \"random error\". \"example2()\"",
                 test2
  end

  test "soil height interpolation" do
    ops = [
      {:x, :=, 0.0},
      {:y, :=, 0.0},
      {:speed_x, :=, 100},
      {:speed_y, :=, 100},
      {:y, :=, 80.0},
      {:x, :=, 0.0},
      {:y, :=, 3},
      {:y, :+, 2.0},
      {:speed_y, :=, 50},
      {:z, :=, 0.0},
      {:speed_z, :=, 100},
      {:safe_z, :=, false},
      {:z, :=, 0.0},
      {:z, :=, {:skip, :soil_height}},
      {:z, :+, -21},
      {:safe_z, :=, true}
    ]

    expect(FarmbotOS.Celery.SpecialValue, :soil_height, 1, fn coord ->
      assert coord.x == 0.0
      assert coord.y == 5.0

      3.141
    end)

    expected = %{
      safe_z: true,
      speed_x: 100,
      speed_y: 50,
      speed_z: 100,
      x: 0.0,
      y: 5.0,
      z: -17.859
    }

    result = Enum.reduce(ops, %{}, &Move.reducer/2)
    assert result == expected
  end
end
