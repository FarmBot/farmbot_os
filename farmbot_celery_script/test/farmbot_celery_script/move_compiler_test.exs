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
  @current_location %{
    kind: :special_value,
    args: %{label: "current_location"}
  }

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

    fake_variance = %{ kind: :random, args: %{variance: 10} }

    assert Compiler.Move.to_number(:x, vec) == x
    assert Compiler.Move.to_number(:y, vec) == y
    assert Compiler.Move.to_number(:z, vec) == z
    assert Compiler.Move.to_number(:x, @current_location) == x
    assert Compiler.Move.to_number(:y, @current_location) == y
    assert Compiler.Move.to_number(:z, @current_location) == z
    assert Compiler.Move.to_number(:z, @safe_height) == 0
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
