defmodule Farmbot.Firmware.StubHandler do
  @moduledoc "Stubs out firmware functionality when you don't have an arduino."

  use GenStage
  use Farmbot.Logger

  @behaviour Farmbot.Firmware.Handler
  alias Farmbot.Firmware.Vec3

  ## Firmware Handler Behaviour.

  def start_link do
    Logger.warn(3, "Firmware is being stubbed.")
    GenStage.start_link(__MODULE__, [])
  end

  def move_absolute(handler, pos, x_speed, y_speed, z_speed) do
    GenStage.call(handler, {:move_absolute, pos, x_speed, y_speed, z_speed})
  end

  def calibrate(handler, axis, speed) do
    GenStage.call(handler, {:calibrate, axis, speed})
  end

  def find_home(handler, axis, speed) do
    GenStage.call(handler, {:find_home, axis, speed})
  end

  def home(handler, axis, speed) do
    GenStage.call(handler, {:home, axis, speed})
  end

  def zero(handler, axis) do
    GenStage.call(handler, {:zero, axis})
  end

  def update_param(handler, param, val) do
    GenStage.call(handler, {:update_param, param, val})
  end

  def read_param(handler, param) do
    GenStage.call(handler, {:read_param, param})
  end

  def read_all_params(handler) do
    GenStage.call(handler, :read_all_params)
  end

  def emergency_lock(handler) do
    GenStage.call(handler, :emergency_lock)
  end

  def emergency_unlock(handler) do
    GenStage.call(handler, :emergency_unlock)
  end

  def set_pin_mode(handler, pin, mode) do
    GenStage.call(handler, {:set_pin_mode, pin, mode})
  end

  def read_pin(handler, pin, pin_mode) do
    GenStage.call(handler, {:read_pin, pin, pin_mode})
  end

  def write_pin(handler, pin, pin_mode, value) do
    GenStage.call(handler, {:write_pin, pin, pin_mode, value})
  end

  def request_software_version(handler) do
    GenStage.call(handler, :request_software_version)
  end

  ## GenStage Behaviour

  defmodule State do
    defstruct pos: nil,
              fw_params: %{},
              locked?: false
  end

  defp do_idle(pid) do
    Process.send_after(pid, :idle_timer, 3000)
  end

  def init([]) do
    state = %State{pos: struct(Vec3)}
    do_idle(self())
    {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(_amnt, state) do
    {:noreply, [], state}
  end

  def handle_info(:idle_timer, state) do
    do_idle(self())
    {:noreply, [:idle], state}
  end

  def handle_call({:move_absolute, pos, _x_speed, _y_speed, _z_speed}, _from, state) do
    {:reply, :ok, [{:report_current_position, pos.x, pos.y, pos.z}, :done], %{state | pos: pos}}
  end

  def handle_call({:calibrate, _axis, _speed}, _from, state) do
    {:reply, :ok, [:done], state}
  end

  def handle_call({:find_home, _axis, _speed}, _from, state) do
    {:reply, :ok, [:done], state}
  end

  def handle_call({:home, axis, _speed}, _from, state) do
    state = %{state | pos: %{state.pos | axis => 0}}
    case axis do
      :x -> {:reply, :ok, [:report_axis_home_complete_x, {:report_current_position, 0, state.pos.y, state.pos.z}, :done], state}
      :y -> {:reply, :ok, [:report_axis_home_complete_y, {:report_current_position, state.pos.x, 0, state.pos.z}, :done], state}
      :z -> {:reply, :ok, [:report_axis_home_complete_z, {:report_current_position, state.pos.x, state.pos.y, 0}, :done], state}
    end
  end

  def handle_call({:read_pin, pin, mode}, _from, state) do
    {:reply, :ok, [{:report_pin_mode, pin, mode}, {:report_pin_value, pin, 1}, :done], state}
  end

  def handle_call({:write_pin, pin, mode, value}, _from, state) do
    {:reply, :ok, [{:report_pin_mode, pin, mode}, {:report_pin_value, pin, value}, :done], state}
  end

  def handle_call({:set_pin_mode, pin, mode}, _from, state) do
    {:reply, :ok, [{:report_pin_mode, pin, mode}, :done], state}
  end

  def handle_call({:zero, axis}, _from, state) do
    state = %{state | pos: %{state.pos | axis => 0}}
    case axis do
      :x -> {:reply, :ok, [{:report_current_position, 0, state.pos.y, state.pos.z}, :done], state}
      :y -> {:reply, :ok, [{:report_current_position, state.pos.x, 0, state.pos.z}, :done], state}
      :z -> {:reply, :ok, [{:report_current_position, state.pos.x, state.pos.y, 0}, :done], state}
    end
  end

  def handle_call({:update_param, param, val}, _from, state) do
    {:reply, :ok, [:done], %{state | fw_params: Map.put(state.fw_params, param, val)}}
  end

  def handle_call({:read_param, param}, _from, state) do
    res = state.fw_params[param]
    {:reply, :ok, [{:report_paramater_value, param, res}, :done], state}
  end

  def handle_call(:read_all_params, _from, state) do
    {:reply, :ok, [:report_params_complete, :done], state}
  end

  def handle_call(:emergency_lock, _from, state) do
    {:reply, :ok, [:done], state}
  end

  def handle_call(:emergency_unlock, _from, state) do
    {:reply, :ok, [:done], state}
  end

  def handle_call(:request_software_version, _, state) do
    {:reply, :ok, [{:report_software_version, "STUBFW"}, :done], state}
  end
end
