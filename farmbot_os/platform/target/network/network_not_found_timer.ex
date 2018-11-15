defmodule Farmbot.Target.Network.NotFoundTimer do
  use GenServer
  import Farmbot.Config, only: [get_config_value: 3]
  require Farmbot.Logger

  def query do
    GenServer.call(__MODULE__, :query)
  end

  def start do
    GenServer.call(__MODULE__, :start)
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init([]) do
    {:ok, %{timer: nil}}
  end

  def handle_call(:query, _, state) do
    if state.timer do
      r = Process.read_timer(state.timer)
      {:reply, r, state}
    else
      {:reply, nil, state}
    end
  end

  def handle_call(:start, _from, %{timer: nil} = state) do
    minutes = get_config_value(:float, "settings", "network_not_found_timer") || 1
    ms = (minutes * 60_000) |> round()
    timer = Process.send_after(self(), :timer, ms)
    Farmbot.Logger.debug(1, "Starting network not found timer: #{minutes} minute(s)")
    {:reply, :ok, %{state | timer: timer}}
  end

  # Timer already started
  def handle_call(:start, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call(:stop, _from, state) do
    if state.timer do
      Process.cancel_timer(state.timer)
    end

    {:reply, :ok, %{state | timer: nil}}
  end

  def handle_info(:timer, state) do
    delay_minutes = get_config_value(:float, "settings", "network_not_found_timer") || 1
    disable_factory_reset? = get_config_value(:bool, "settings", "disable_factory_reset")
    first_boot? = get_config_value(:bool, "settings", "first_boot")

    cond do
      disable_factory_reset? ->
        Farmbot.Logger.warn(1, "Factory reset is disabled. Not resetting.")
        {:noreply, %{state | timer: nil}}

      first_boot? ->
        msg = """
        Network not found after #{delay_minutes} minute(s).
        possible causes of this include:

        1) A typo if you manually inputted the SSID.

        2) The access point is out of range

        3) There is too much radio interference around Farmbot.

        5) There is a hardware issue.
        """

        Farmbot.Logger.error(1, msg)
        Farmbot.System.factory_reset(msg)
        {:stop, :normal, %{state | timer: nil}}

      true ->
        Farmbot.Logger.error(1, "Network not found after timer. Farmbot is disconnected.")

        msg = """
        Network not found after #{delay_minutes} minute(s).
        This can happen if your wireless access point is no longer available,
        out of range, or there is too much radio interference around Farmbot.
        If you see this message intermittently you should disable \"automatic
        factory reset\" or tune the \"network not found
        timer\" value in the Farmbot Web Application.
        """

        Farmbot.System.factory_reset(msg)
        {:stop, :normal, %{state | timer: nil}}
    end
  end
end
