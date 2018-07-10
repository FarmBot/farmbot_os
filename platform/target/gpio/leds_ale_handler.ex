defmodule Farmbot.Target.Leds.AleHandler do
  alias ElixirALE.GPIO
  @behaviour Farmbot.Leds.Handler

  @slow_blink_speed 200
  @fast_blink_speed 50

  # @valid_status [:off, :solid, :slow_blink, :fast_blink]

  @moduledoc false
  def red(status), do: GenServer.call(__MODULE__, {:red, status})
  def blue(status), do: GenServer.call(__MODULE__, {:blue, status})
  def green(status), do: GenServer.call(__MODULE__, {:green, status})
  def yellow(status), do: GenServer.call(__MODULE__, {:yellow, status})
  def white1(status), do: GenServer.call(__MODULE__, {:white1, status})
  def white2(status), do: GenServer.call(__MODULE__, {:white2, status})
  def white3(status), do: GenServer.call(__MODULE__, {:white3, status})
  def white4(status), do: GenServer.call(__MODULE__, {:white4, status})
  def white5(status), do: GenServer.call(__MODULE__, {:white5, status})

  use GenServer

  def start_link(_, opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    leds = [:red, :blue, :green, :yellow, :white1, :white2, :white3, :white4, :white5]

    state =
      Map.new(leds, fn color ->
        {:ok, pid} = GPIO.start_link(color_to_pin(color), :output)
        :ok = GPIO.write(pid, 0)
        {color, %{pid: pid, status: :off, blink_timer: nil, state: 0}}
      end)

    {:ok, state}
  end

  def handle_call({color, :off}, _from, state) do
    :ok = GPIO.write(state[color].pid, 0)
    :ok = cancel_timer(state[color].blink_timer)

    {:reply, :ok,
     update_color(state, color, %{state[color] | state: 0, blink_timer: nil, status: :off})}
  end

  def handle_call({color, :solid}, _from, state) do
    :ok = GPIO.write(state[color].pid, 1)
    :ok = cancel_timer(state[color].blink_timer)

    {:reply, :ok,
     update_color(state, color, %{state[color] | state: 1, blink_timer: nil, status: :off})}
  end

  def handle_call({color, :slow_blink}, _from, state) do
    timer = restart_timer(state[color].blink_timer, color, @slow_blink_speed)

    {:reply, :ok,
     update_color(state, color, %{state[color] | blink_timer: timer, status: :slow_blink})}
  end

  def handle_call({color, :fast_blink}, _from, state) do
    timer = restart_timer(state[color].blink_timer, color, @fast_blink_speed)

    {:reply, :ok,
     update_color(state, color, %{state[color] | blink_timer: timer, status: :slow_blink})}
  end

  def handle_info({:blink_timer, color}, state) do
    new_led_state = invert(state[color].state)
    :ok = GPIO.write(state[color].pid, new_led_state)

    new_state =
      case state[color] do
        %{status: :slow_blink} ->
          timer = restart_timer(state[color].blink_timer, color, @slow_blink_speed)
          n = %{state[color] | state: new_led_state, blink_timer: timer, status: :slow_blink}
          update_color(state, color, n)

        %{status: :fast_blink} ->
          timer = restart_timer(state[color].blink_timer, color, @fast_blink_speed)
          n = %{state[color] | state: new_led_state, blink_timer: timer, status: :fast_blink}
          update_color(state, color, n)
      end

    {:noreply, new_state}
  end

  defp color_to_pin(:red), do: 17
  defp color_to_pin(:yellow), do: 23
  defp color_to_pin(:green), do: 24
  defp color_to_pin(:blue), do: 25
  defp color_to_pin(:white1), do: 27
  defp color_to_pin(:white2), do: 6
  defp color_to_pin(:white3), do: 21
  defp color_to_pin(:white4), do: 12
  defp color_to_pin(:white5), do: 13

  defp cancel_timer(nil), do: :ok

  defp cancel_timer(ref) do
    Process.cancel_timer(ref)
    :ok
  end

  defp restart_timer(timer, color, timeout) do
    :ok = cancel_timer(timer)
    Process.send_after(self(), {:blink_timer, color}, timeout)
  end

  defp invert(0), do: 1
  defp invert(1), do: 0

  defp update_color(state, color, new_color) do
    %{state | color => new_color}
  end
end
