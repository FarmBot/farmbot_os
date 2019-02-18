defmodule Farmbot.CeleryScript.Syscalls do
  alias Farmbot.CeleryScript.{AST, Compiler}

  def test(params \\ []) do
    File.read!("fixture/sequence_pair.json")
    |> Jason.decode!()
    |> Enum.at(0)
    |> AST.decode()
    |> Compiler.compile()
    |> Code.eval_quoted()
    |> elem(0)
    # generates the sequence
    |> apply([params])
    |> Enum.map(fn step -> apply(step, []) end)
  end

  def point(type, id) do
    IO.puts("point(#{type}, #{id})")
    %{x: 1, y: 122, z: 100}
  end

  def coordinate(x, y, z) do
    IO.puts("coodinate(#{x}, #{y}, #{z})")
    %{x: x, y: y, z: z}
  end

  def move_absolute(x, y, z, speed) do
    IO.puts("move_absolute(#{x}, #{y}, #{z}, #{speed})")
  end

  def get_current_x() do
    100
  end

  def get_current_y() do
    234
  end

  def get_current_z() do
    12
  end

  def write_pin(pin, mode, value) do
    IO.puts("write_pin(#{pin}, #{mode}, #{value}")
  end

  def pin(type, id) do
    IO.puts("pin(#{type}, #{id})")
  end

  def read_pin(pin, mode) do
    IO.puts("read_pin(#{pin}, #{mode})")
  end

  def find_home(axis, speed) do
    IO.puts("find_home(#{axis}, #{speed})")
  end

  def find_home(axis) do
    IO.puts("find_home(#{axis})")
  end

  def send_message(level, message, channels) do
    IO.puts("send_message(#{level}, #{message}, #{inspect(channels)}")
  end

  def nothing do
    IO.puts("nothing()")
  end

  def get_sequence(id) do
    IO.puts("get_sequence(#{id})")

    File.read!("fixture/sequence_pair.json")
    |> Jason.decode!()
    |> Enum.at(1)
    |> AST.decode()
  end

  def execute_script(name, env) do
    IO.puts("execute_script(#{name}, #{inspect(env)})")
  end
end
