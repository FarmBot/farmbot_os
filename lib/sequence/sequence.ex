defmodule Sequence do
  @moduledoc """
    LOL
  """
  use GenServer
  require Logger
  require Kernel
  def init(_) do
    {:ok, %{}}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def handle_cast({:add_step, {position, function}}, steps) do
    {:noreply, Map.update(steps, position, function, fn _x -> function end)}
  end

  def handle_call({:get_steps}, _from, steps) do
    {:reply, steps, steps}
  end

  def handle_call({:clean_steps}, _from, steps) do
    {:reply, steps, %{}}
  end

  def handle_call({:execute, _id}, _from, steps) do
    Logger.debug("#{inspect steps}")
    ordered_steps = Enum.sort(steps)
    ordered_list = Enum.map(ordered_steps, fn({_pos, step}) -> step end)
    Logger.debug("#{inspect ordered_list}")
    pid = spawn fn -> Enum.each(ordered_list, fn step -> Kernel.apply(step, []) end) end
    {:reply, pid, %{}}
  end

  def execute(id \\nil) do
    GenServer.call(__MODULE__, {:execute, id})
  end

  # Pattern match available commands
  def add_step(step,id \\ nil)
  def add_step(%{"command" => command, "message_type" => "move_absolute",
                "position" => position}, _id) do
    #TODO: i think this would allow negative numbers
    xpos = String.to_integer(Map.get(command, "x", nil))
    ypos = String.to_integer(Map.get(command, "y", nil))
    zpos = String.to_integer(Map.get(command, "z", nil))
    speed = String.to_integer(Map.get(command, "speed", nil))
    GenServer.cast(__MODULE__, {:add_step, {position, fn -> Command.move_absolute(xpos,ypos,zpos,speed) end}})
  end

  def add_step(%{"command" => %{"speed" => speed,
                                "x" => x, "y" => y, "z" => z},
                                "id" => _istep_d,
                                "message_type" => "move_relative",
                                "position" => position, "sequence_id" => _seq_id}, _id) do
    GenServer.cast(__MODULE__,
      {:add_step, {position,
        fn -> Command.move_relative(%{x: String.to_integer(x), y: String.to_integer(y), z: String.to_integer(z), speed: speed}) end}})
  end

  # Write pin (MODE IS NOT WORKING?)
  def add_step(%{"command" => %{"mode" => _mode, "pin" => pin, "value" => value}, "message_type" => "pin_write", "position" => position}, _id) do
    GenServer.cast(__MODULE__,
      {:add_step, {position, fn -> Command.write_pin(String.to_integer(pin), String.to_integer(value),0) end}})
  end

  # Process.sleep seems to be off by a couple seconds?
  def add_step(%{"command" => %{"value" => milis}, "message_type" => "wait", "position" => position}, _id) do
    GenServer.cast(__MODULE__,
      {:add_step, {position, fn -> Process.sleep(String.to_integer(milis)) end}})
  end

  def add_step(%{"command" => command, "message_type" => "read_pin", "position" => position}, _id) do
    # I dont know what this is supposed to do ???
    Logger.debug("add_step: COMMAND: #{inspect command}, POSITION: #{inspect position}")
  end

  def add_step(step, _id) do
    Logger.debug("Unable to add step: #{inspect step}")
  end

  def add_steps(steps, id) when is_list(steps) do
    Enum.each(steps, fn step -> add_step(step, id)  end)
  end

  def get_steps do
    GenServer.call(__MODULE__, {:get_steps})
  end

  def clean_steps do
    GenServer.call(__MODULE__, {:clean_steps})
  end
end
