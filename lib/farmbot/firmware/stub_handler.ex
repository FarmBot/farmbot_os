defmodule Farmbot.Firmware.StubHandler do
  @moduledoc "Stubs out firmware functionality when you don't have an arduino."
  use GenStage
  require Logger

  @behaviour Farmbot.Firmware.Handler
  @msgs [
    :dance_x,
    :dance_y,
    :dance_z
  ]

  def start_link do
    Logger.warn("Firmware is being stubbed.")
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def write(code) do
    GenStage.call(__MODULE__, {:write, code})
  end

  def init([]) do
    @msgs |> pick_random() |> send_random(self())
    {:producer, %{position: %{x: 0, y: 0, z: 0}}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(_amnt, state) do
    {:noreply, [], state}
  end

  def handle_call({:write, _string}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_info(:dance_x, %{position: %{x: x}} = state) do
    state = %{state | position: %{state.position | x: math(x)}}
    @msgs |> pick_random() |> send_random(self())
    {:noreply, [{:report_current_position, state.position.x, state.position.y, state.position.z}], state}
  end

  def handle_info(:dance_y, %{position: %{y: y}} = state) do
    state = %{state | position: %{state.position | y: math(y)}}
    @msgs |> pick_random() |> send_random(self())
    {:noreply, [{:report_current_position, state.position.x, state.position.y, state.position.z}], state}
  end

  def handle_info(:dance_z, %{position: %{z: z}} = state) do
    state = %{state | position: %{state.position | z: math(z)}}
    @msgs |> pick_random() |> send_random(self())
    {:noreply, [{:report_current_position, state.position.x, state.position.y, state.position.z}], state}
  end

  def send_random(msg, pid) do
    Process.send_after(pid, msg, random_int())
  end

  def pick_random(l), do: Enum.random(l)

  def random_int(max \\ nil) do
    :rand.uniform(max || 100)
  end

  def math(num) do
    apply(Kernel, Enum.random([:-, :+]), [num, random_int(20)])
  end
end
