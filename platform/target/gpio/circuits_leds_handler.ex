defmodule FarmbotOS.Platform.Target.Leds.CircuitsHandler do
  @moduledoc "Circuits gpio handler for LEDS"

  alias Circuits.GPIO
  use GenServer
  @behaviour FarmbotOS.Leds.Handler
  alias FarmbotOS.Leds.StubHandler

  @slow_blink_speed 1000
  @fast_blink_speed 250
  @really_fast_blink_speed 100

  def red(status) do
    _ = StubHandler.red(status)
    GenServer.call(__MODULE__, {:red, status})
  end

  def blue(status) do
    _ = StubHandler.blue(status)
    GenServer.call(__MODULE__, {:blue, status})
  end

  def green(status) do
    _ = StubHandler.green(status)
    GenServer.call(__MODULE__, {:green, status})
  end

  def yellow(status) do
    _ = StubHandler.yellow(status)
    GenServer.call(__MODULE__, {:yellow, status})
  end

  def white1(status) do
    _ = StubHandler.white1(status)
    GenServer.call(__MODULE__, {:white1, status})
  end

  def white2(status) do
    _ = StubHandler.white2(status)
    GenServer.call(__MODULE__, {:white2, status})
  end

  def white3(status) do
    _ = StubHandler.white3(status)
    GenServer.call(__MODULE__, {:white3, status})
  end

  def white4(status) do
    _ = StubHandler.white4(status)
    GenServer.call(__MODULE__, {:white4, status})
  end

  def white5(status) do
    _ = StubHandler.white5(status)
    GenServer.call(__MODULE__, {:white5, status})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    leds = [
      :red,
      :blue,
      :green,
      :yellow,
      :white1,
      :white2,
      :white3,
      :white4,
      :white5
    ]

    state =
      Map.new(leds, fn color ->
        {:ok, ref} = GPIO.open(color_to_pin(color), :output)
        :ok = GPIO.set_pull_mode(ref, :none)
        :ok = GPIO.write(ref, 0)
        {color, %{ref: ref, status: :off, blink_timer: nil, state: 0}}
      end)

    {:ok, state}
  end

  def handle_call({color, :off}, _from, state) do
    :ok = GPIO.write(state[color].ref, 0)
    :ok = cancel_timer(state[color].blink_timer)

    {:reply, :ok,
     update_color(state, color, %{
       state[color]
       | state: 0,
         blink_timer: nil,
         status: :off
     })}
  end

  def handle_call({color, :solid}, _from, state) do
    :ok = GPIO.write(state[color].ref, 1)
    :ok = cancel_timer(state[color].blink_timer)

    {:reply, :ok,
     update_color(state, color, %{
       state[color]
       | state: 1,
         blink_timer: nil,
         status: :off
     })}
  end

  def handle_call({color, :slow_blink}, _from, state) do
    timer = restart_timer(state[color].blink_timer, color, @slow_blink_speed)

    {:reply, :ok,
     update_color(state, color, %{
       state[color]
       | blink_timer: timer,
         status: :slow_blink
     })}
  end

  def handle_call({color, :fast_blink}, _from, state) do
    timer = restart_timer(state[color].blink_timer, color, @fast_blink_speed)

    {:reply, :ok,
     update_color(state, color, %{
       state[color]
       | blink_timer: timer,
         status: :fast_blink
     })}
  end

  def handle_call({color, :really_fast_blink}, _from, state) do
    timer =
      restart_timer(state[color].blink_timer, color, @really_fast_blink_speed)

    {:reply, :ok,
     update_color(state, color, %{
       state[color]
       | blink_timer: timer,
         status: :really_fast_blink
     })}
  end

  def handle_info({:blink_timer, color}, state) do
    new_state =
      case state[color] do
        %{status: :slow_blink} ->
          new_led_state = invert(state[color].state)
          :ok = GPIO.write(state[color].ref, new_led_state)

          timer =
            restart_timer(state[color].blink_timer, color, @slow_blink_speed)

          n = %{
            state[color]
            | state: new_led_state,
              blink_timer: timer,
              status: :slow_blink
          }

          update_color(state, color, n)

        %{status: :fast_blink} ->
          new_led_state = invert(state[color].state)
          :ok = GPIO.write(state[color].ref, new_led_state)

          timer =
            restart_timer(state[color].blink_timer, color, @fast_blink_speed)

          n = %{
            state[color]
            | state: new_led_state,
              blink_timer: timer,
              status: :fast_blink
          }

          update_color(state, color, n)

        %{status: :really_fast_blink} ->
          new_led_state = invert(state[color].state)
          :ok = GPIO.write(state[color].ref, new_led_state)

          timer =
            restart_timer(
              state[color].blink_timer,
              color,
              @really_fast_blink_speed
            )

          n = %{
            state[color]
            | state: new_led_state,
              blink_timer: timer,
              status: :really_fast_blink
          }

          update_color(state, color, n)

        _ ->
          state
      end

    {:noreply, new_state}
  end

  defp color_to_pin(:red), do: 17
  defp color_to_pin(:yellow), do: 23
  defp color_to_pin(:white1), do: 27
  defp color_to_pin(:white2), do: 06
  defp color_to_pin(:white3), do: 21
  defp color_to_pin(:green), do: 24
  defp color_to_pin(:blue), do: 25
  defp color_to_pin(:white4), do: 12
  defp color_to_pin(:white5), do: 13

  defp cancel_timer(ref) do
    FarmbotOS.Time.cancel_timer(ref)
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
