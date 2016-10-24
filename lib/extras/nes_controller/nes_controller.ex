defmodule NesController do
  require Bitwise
  @latch_out 10
  @clock_out 9
  @data_in 25

  #       | A | B | SEL | STA | UP | DWN | LFT | RIGHT |
  @a       01111111
  @b       10111111
  @select  11011111
  @start   11101111
  @up      11110111
  @down    11111011
  @left    11111101
  @right   11111110
  @none    11111111


  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid, name: __MODULE__)
  end

  def init(pid) do
    {:ok, latch} = Gpio.start_link(@latch_out, :output)
    {:ok, clock} = Gpio.start_link(@clock_out, :output)
    {:ok, data}  = Gpio.start_link(@data_in, :input)
    Gpio.write(latch,1) # Write latch high
    Gpio.write(clock,1) # write clock high
    spawn fn -> read_controller(latch, clock, data) end
    state = {@none, pid}
    {:ok, state}
  end

  def handle_info(@up, {button, pid})
    when button != @up do
    send(pid, :up)
    {:noreply, {@up, pid}}
  end

  def handle_info(@down, {button, pid})
    when button != @down do
    send(pid, :down)
    {:noreply, {@down, pid}}
  end

  def handle_info(@left, {button, pid})
    when button != @left do
    send(pid, :left)
    {:noreply, {@left, pid}}
  end

  def handle_info(@right, {button, pid})
    when button != @right do
    send(pid, :right)
    {:noreply, {@right, pid}}
  end

  def handle_info(@a, {button, pid})
    when button != @a do
    send(pid, :a)
    {:noreply, {@a, pid}}
  end

  def handle_info(@b, {button, pid})
    when button != @b do
    send(pid, :b)
    {:noreply, {@b, pid}}
  end

  def handle_info(@start, {button, pid})
    when button != @start do
    send(pid, :start)
    {:noreply, {@start, pid}}
  end

  def handle_info(@select, {button, pid})
    when button != @select do
    send(pid, :select)
    {:noreply, {@select, pid}}
  end

  def handle_info(button, {last_button, pid})
  when button == last_button do
    {:noreply, {last_button, pid}}
  end

  # If the callback wants to handle multiple button pushes.
  def handle_info(button, {_, pid}) do
    send(pid, button)
    {:noreply, {button, pid}}
  end

  def handle_info(@none, {_, pid}) do
    {:noreply, {@none, pid}}
  end

  def handle_info(info, state) do
    IO.inspect info
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
