defmodule Farmbot.Network.Ntp do
  @moduledoc """
    Sets time.
  """

  require Logger
  @doc """
    Tries to set the time from ntp.
    This will try 3 times to set the time. if it fails the thrid time,
    it will return an error
  """
  @spec set_time :: :ok | {:error, term}
  def set_time do
    Logger.debug ">> is getting time from NTP."
    f = do_try_set_time
    Logger.debug ">> ntp: #{inspect f}"
  end

  defp do_try_set_time(), do: do_try_set_time(0)
  defp do_try_set_time(count) when count < 4 do
    # we try to set ntp time 3 times before giving up.
    Logger.debug ">> trying to set time (try #{count})"
    cmd = "ntpd -q -n -p 0.pool.ntp.org -p 1.pool.ntp.org"
    port = Port.open({:spawn, cmd},
      [:stream,
       :binary,
       :exit_status,
       :hide,
       :use_stdio,
       :stderr_to_stdout])
     case handle_port(port) do
       :ok -> :ok
       {:error, _} ->
         Logger.debug ">> failed to get time. trying again."
         # kill old ntp if it exists
         System.cmd("killall", ["ntpd"])
         # sleep for a second
         Process.sleep(1000)
         do_try_set_time(count + 1)
     end
  end
  defp do_try_set_time(_) do
    {:error, :timeout}
  end

  defp handle_port(port) do
    receive do
      # This is so ugly lol
      {^port, {:data, "ntpd: bad address" <> _}} -> {:error, :bad_address}
      # print things that ntp says
      {^port, {:data, data}} ->
        IO.puts "ntp got stuff: #{data}"
        handle_port(port)
      # when ntp exits, check to make sure its REALLY set
      {^port, {:exit_status, 0}} ->
        if :os.system_time(:seconds) < 1_474_929 do
          {:error, :not_set}
        else
          :ok
        end
    end
  end
end
