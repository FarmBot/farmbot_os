defmodule Farmbot.System.Network.Ntp do
  @moduledoc """
    Sets time.
  """

  require Logger
  alias Farmbot.{DebugLog}
  use   DebugLog

  @doc """
    Tries to set the time from ntp.
    This will try 3 times to set the time. if it fails the thrid time,
    it will return an error
  """
  @spec set_time(integer) :: :ok | {:error, term}
  def set_time(tries \\ 0)
  def set_time(tries) when tries < 4 do
    Process.sleep(1000 * tries)
    case :inet_res.gethostbyname('0.pool.ntp.org') do
      {:ok, {:hostent, _url, _, _, _, _}} ->
        do_try_set_time(tries)
      {:error, err} ->
        debug_log "Failed to set time (#{tries}): DNS Lookup: #{inspect err}"
        set_time(tries + 1)
    end
  end

  def set_time(_), do: {:error, :timeout}

  defp do_try_set_time(tries) when tries < 4 do
    # we try to set ntp time 3 times before giving up.
    Logger.info ">> trying to set time (try #{tries})"
    :os.cmd('ntpd -p 0.pool.ntp.org -p 1.pool.ntp.org')
    wait_for_time(tries)
  end

  defp wait_for_time(tries, loops \\ 0)

  defp wait_for_time(tries, loops) when loops > 5 do
    :os.cmd('killall ntpd')
    set_time(tries)
  end

  defp wait_for_time(tries, loops) do
    case :os.system_time do
      t when t > 1_474_929 ->
        Logger.flush()
        Logger.info ">> Time is set.", type: :success
        :ok
      _ ->
        Process.sleep(1_000 * loops)
        wait_for_time(tries, loops + 1)
    end
  end

end
