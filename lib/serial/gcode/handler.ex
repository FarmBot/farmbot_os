defmodule Farmbot.Serial.Gcode.Handler do
  @moduledoc """
    Handles parsed messages.
  """
  require Logger
  use GenServer
  alias Farmbot.BotState
  alias Farmbot.Lib.Maths

  @type state :: map

  @doc """
    Starts the gcode handler
  """
  @spec start_link(pid) :: {:ok, pid}
  def start_link(nerves),
    do: GenServer.start_link(__MODULE__, nerves, name: __MODULE__)

  @spec init(pid) :: {:ok, state}
  def init(nerves) do
    {:ok, %{nerves: nerves, current: nil, log: []}}
  end

  @spec handle_cast(any, state) :: {:noreply, state}
  # Don't log messages there is to many.
  def handle_cast({:debug_message, str}, state) do
    IO.puts str
    {:noreply, state}
  end

  def handle_cast({:idle, _}, state) do
    {:noreply, %{nerves: state.nerves, current: nil, log: []}}
  end

  def handle_cast({:busy, _}, state) do
    {_, pid} = state.current
    send(pid, :busy)
    Logger.info ">>'s arduino is busy.", type: :busy
    {:noreply, state}
  end

  def handle_cast({:done, _}, %{nerves: nerves, current: {_current_str, pid},
    log: log})
  do
    send(pid, :done)
    case List.first(log) do
      {nextstr, new_pid} ->
        Farmbot.Serial.Handler.write(nextstr, new_pid)
        {:noreply, %{nerves: nerves, current: {nextstr, new_pid},
          log: log -- [{nextstr, new_pid}]}}
      nil ->
        {:noreply, %{nerves: nerves, current: nil, log: []}}
    end
  end

  def handle_cast({:done, _}, state) do
    {:noreply, %{nerves: state.nerves, current: nil, log: []}}
  end

  def handle_cast({:received, _}, state) do
    {:noreply, state}
  end

  def handle_cast({:report_pin_value, pin, value, _}, state)
  when is_integer(pin) and is_integer(value) do
    BotState.set_pin_value(pin, value)
    {:noreply, state}
  end

  def handle_cast({:report_current_position, x_steps,y_steps,z_steps, _}, state) do
    BotState.set_pos(
      Maths.steps_to_mm(x_steps, spm(:x)),
      Maths.steps_to_mm(y_steps, spm(:y)),
      Maths.steps_to_mm(z_steps, spm(:z)))
    {:noreply, state}
  end

  def handle_cast({:report_parameter_value, param, value, _}, state)
  when is_atom(param) and is_integer(value) do
    BotState.set_param(param, value)
    {:noreply, state}
  end

  def handle_cast({:reporting_end_stops, x1,x2,y1,y2,z1,z2,_}, state) do
    BotState.set_end_stops({x1,x2,y1,y2,z1,z2})
    {:noreply, state}
  end

  # If we arent waiting on anything right now. (current is nil and log is empty)
  def handle_cast({:send, message, caller},
    %{nerves: nerves, current: nil, log: []})
    when is_bitstring(message)
  do
    Farmbot.Serial.Handler.write(message, caller)
    {:noreply, %{nerves: nerves, current: {message, caller}, log: []}}
  end

  def handle_cast({:send, message, caller},
                  %{nerves: nerves, current: current, log: log}) do
    {:noreply,
     %{nerves: nerves, current: current, log: log ++ [{message, caller}]}}
  end

  def handle_cast({:unhandled_gcode, code}, state) do
    Logger.info ">> got an unhandled gcode! #{code}"
    {:noreply, state}
  end

  def handle_cast({:report_software_version, version}, state) do
    parsed_version = parse_version(version)
    BotState.set_fw_version(parsed_version)
    {:noreply, state}
  end

  def handle_cast(:dont_handle_me, state), do: {:noreply, state}

  def handle_cast(event, state) do
    Logger.info ">> got an unhandled event! #{inspect event}"
    {:noreply, state}
  end

  @spec handle_call(any, any, state) :: {:reply, any, state}
  def handle_call(:state, _from, state), do: {:reply, state, state}

  @spec spm(atom) :: integer
  defp spm(xyz) do
    "steps_per_mm_#{xyz}"
    |> String.to_atom
    |> Farmbot.BotState.get_config()
  end

  @spec parse_version(binary) :: binary
  defp parse_version(version) do
    [derp | _] = String.split(version, " Q0")
    derp
  end

  @doc """
    Sends a message and blocks until it completes, or times out.
    The default timeout is ten seconds.
  """
  @spec block_send(binary, integer) :: {:error, :no_serial} | atom
  def block_send(str, timeout \\ 10_000)
  def block_send(str, timeout) do
    if str == "F83" do
      IO.puts "UHHHH"
      BotState.set_fw_version("WAITING FOR ARDUINO")
    end

    if Farmbot.Serial.Handler.available? do
      GenServer.cast(Farmbot.Serial.Gcode.Handler, {:send, str, self()})
      block(timeout)
    else
      {:error, :no_serial}
    end
  end

  @doc """
    Blocks current process until a serial command returns.
  """
  @spec block(integer) :: atom
  def block(timeout) do
    receive do
      :done -> :done
      :e_stop ->
        GenServer.cast(__MODULE__, {:done, nil})
        :e_stop
      :busy -> block(timeout)
      error -> error
    after
      timeout -> :timeout
    end
  end

  # I think i put these here to clean up the logs
  @spec terminate(atom, state) :: no_return
  def terminate(:normal, _state), do: :ok
end
