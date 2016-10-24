defmodule NesController do
  require Logger
  require Bitwise
  @latch_out 10
  @clock_out 9
  @data_in 25
  @up      11110111
  @down    11111011
  @left    11111101
  @right   11111110
  @select  11011111
  @start   11101111
  @a       01111111
  @b       10111111
  @none    11111111

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    {:ok, latch} = Gpio.start_link(@latch_out, :output)
    {:ok, clock} = Gpio.start_link(@clock_out, :output)
    {:ok, data}  = Gpio.start_link(@data_in, :input)
    Gpio.write(latch,1) # Write latch high
    Gpio.write(clock,1) # write clock high
    spawn fn -> read_controller(latch, clock, data) end
    state = @none
    {:ok, state}
  end

  def handle_info(@up, state)
  when state != @up do
    Logger.debug(" up PUSHED ")
    Command.move_relative({:y, 100, 1000})
    {:noreply, @up}
  end

  def handle_info(@down, state)
  when state != @down do
    Logger.debug(" down PUSHED ")
    Command.move_relative({:y, 100, -1000})
    {:noreply, @down}
  end

  def handle_info(@left, state)
  when state != @left do
    Logger.debug(" left PUSHED ")
    Command.move_relative({:x, 100, -1000})
    {:noreply, @left}
  end

  def handle_info(@right, state)
  when state != @right do
    Logger.debug(" right PUSHED ")
    Command.move_relative({:x, 100, 1000})
    {:noreply, @right}
  end

  def handle_info(@a, state)
  when state != @a do
    Logger.debug(" a PUSHED ")
    Command.move_relative({:z, 100, -1000})
    {:noreply, @a}
  end

  def handle_info(@b, state)
  when state != @b do
    Logger.debug(" b PUSHED ")
    Command.move_relative({:z, 100, 1000})
    {:noreply, @b}
  end

  def handle_info(button, state)
  when button == state do
    {:noreply, state}
  end

  def handle_info(@none, _state) do
    {:noreply, @none}
  end

  def handle_info(:done, _state) do
    {:noreply, @none}
  end

  def handle_info(info, state) do
    Logger.debug("#{inspect info}")
    IO.inspect state
    {:noreply, state}
  end

  def read_controller(latch, clock, data) do
    Gpio.write(latch, 0)
    Gpio.write(clock, 0)
    Gpio.write(latch, 1)
    Gpio.write(latch, 0)

    first_bit = Gpio.read(data)
    controller_loop({latch, clock, data}, first_bit, 1)
  end

  def controller_loop({latch, clock, data},bit, 8) do
    send(__MODULE__, Integer.to_string(bit, 2) |> String.to_integer)
    read_controller(latch, clock, data)
  end

  def controller_loop({latch, clock, data}, bit, loop) do
    Gpio.write(clock, 1)
    Process.sleep(1)
    next_bit = bit
    |> Bitwise.bsl(1)
    |>  Kernel.+( Gpio.read(data) )
    Gpio.write(clock, 0)
    controller_loop({latch, clock, data}, next_bit, loop+1)
  end
end
