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

  def move_absolute(handler, pos, x_spd, y_spd, z_spd) do
    GenStage.call(handler, {:move_absolute, pos, x_spd, y_spd, z_spd}, 120_000)
  end

  def calibrate(handler, axis) do
    GenStage.call(handler, {:calibrate, axis})
  end

  def find_home(handler, axis) do
    GenStage.call(handler, {:find_home, axis})
  end

  def home_all(handler) do
    GenStage.call(handler, :home_all)
  end

  def home(handler, axis) do
    GenStage.call(handler, {:home, axis})
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

  def set_servo_angle(handler, pin, number) do
    GenStage.call(handler, {:set_servo_angle, pin, number})
  end

  ## GenStage Behaviour

  defmodule State do
    @moduledoc false
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
    dispatch = if state.locked? do
      []
    else
      [:idle]
    end
    {:noreply, dispatch, state}
  end

  def handle_call(cmd, _from, %{locked?: true} = state) when cmd != :emergency_unlock do
    {:reply, :ok, [:error], state}
  end

  def handle_call({:move_absolute, pos, _x_speed, _y_speed, _z_speed}, _from, state) do
    response = build_resp [{:report_current_position, pos.x, pos.y, pos.z},
                       {:report_encoder_position_scaled, pos.x, pos.y, pos.z},
                       {:report_encoder_position_raw, pos.x, pos.y, pos.z}, :done]
    {:reply, build_reply(:ok), response, %{state | pos: pos}}
  end

  def handle_call({:calibrate, _axis}, _from, state) do
    {:reply, :ok, [:done], state}
  end

  def handle_call({:find_home, axis}, _from, state) do
    state = %{state | pos: %{state.pos | axis => 0}}
    response = build_resp [
      :"report_axis_home_complete_#{axis}",
      {:report_current_position,        state.pos.x, state.pos.y, state.pos.z},
      {:report_encoder_position_scaled, state.pos.x, state.pos.y, state.pos.z},
      {:report_encoder_position_raw,    state.pos.x, state.pos.y, state.pos.z},
      :done
    ]
    {:reply, build_reply(:ok), response, state}
  end

  def handle_call({:home, axis}, _from, state) do
    state = %{state | pos: %{state.pos | axis => 0}}
    response = build_resp [
      :"report_axis_home_complete_#{axis}",
      {:report_current_position,        state.pos.x, state.pos.y, state.pos.z},
      {:report_encoder_position_scaled, state.pos.x, state.pos.y, state.pos.z},
      {:report_encoder_position_raw,    state.pos.x, state.pos.y, state.pos.z},
      :done
    ]
    {:reply, build_reply(:ok), response, state}
  end

  def handle_call(:home_all, _from, state) do
    state = %{state | pos: %{state.pos | x: 0, y: 0, z: 0}}
    response = build_resp [
      :report_axis_home_complete_x,
      :report_axis_home_complete_y,
      :report_axis_home_complete_z,
      {:report_current_position,        state.pos.x, state.pos.y, state.pos.z},
      {:report_encoder_position_scaled, state.pos.x, state.pos.y, state.pos.z},
      {:report_encoder_position_raw,    state.pos.x, state.pos.y, state.pos.z},
      :done
    ]
    {:reply, build_reply(:ok), response, state}
  end

  def handle_call({:read_pin, pin, mode}, _from, state) do
    response = build_resp [
      {:report_pin_mode, pin, mode},
      {:report_pin_value, pin, 1}, :done
    ]
    {:reply, build_reply(:ok), response, state}
  end

  def handle_call({:write_pin, pin, mode, value}, _from, state) do
    response = build_resp [
      {:report_pin_mode, pin, mode},
      {:report_pin_value, pin, value}, :done]
    {:reply, build_reply(:ok), response, state}
  end

  def handle_call({:set_pin_mode, pin, mode}, _from, state) do
    response = [{:report_pin_mode, pin, mode}, :done]
    {:reply, build_reply(:ok), response, state}
  end

  def handle_call({:zero, axis}, _from, state) do
    state = %{state | pos: %{state.pos | axis => 0}}
    response = build_resp [
      {:report_current_position,        state.pos.x, state.pos.y, state.pos.z},
      {:report_encoder_position_scaled, state.pos.x, state.pos.y, state.pos.z},
      {:report_encoder_position_raw,    state.pos.x, state.pos.y, state.pos.z},
      :done
    ]
    {:reply, build_reply(:ok), response, state}
  end

  def handle_call({:update_param, param, val}, _from, state) do
    response = build_resp [{:report_parameter_value, param, val}, :done]
    {:reply, build_reply(:ok), response, %{state | fw_params: Map.put(state.fw_params, param, val)}}
  end

  def handle_call({:read_param, param}, _from, state) do
    res = state.fw_params[param]
    response = build_resp [{:report_parameter_value, param, res}, :done]
    {:reply, build_reply(:ok), response, state}
  end

  def handle_call(:read_all_params, _from, state) do
    {:reply, :ok, [:report_params_complete, :done], state}
  end

  def handle_call(:emergency_lock, _from, state) do
    response = build_resp [:report_emergency_lock, :done]
    {:reply, build_reply(:ok), response, %{state | locked?: true}}
  end

  def handle_call(:emergency_unlock, _from, state) do
    response = build_resp [:done, :idle]
    {:reply, build_reply(:ok), response, %{state | locked?: false}}
  end

  def handle_call(:request_software_version, _, state) do
    response = build_resp [{:report_software_version, "STUBFW"}, :done]
    {:reply, build_reply(:ok), response, state}
  end

  def handle_call({:set_servo_angle, _pin, _angle}, _, state) do
    response = build_resp [:done]
    {:reply, build_reply(:ok), response, state}
  end

  case Mix.env() do
    :prod ->
      defp build_resp(_) do
        [:done]
      end

      defp build_reply(_) do
        {:error, "Firmware Disconnected."}
      end

    _env ->
      defp build_resp(list) do
        list
      end

      defp build_reply(reply) do
        reply
      end
  end

end
