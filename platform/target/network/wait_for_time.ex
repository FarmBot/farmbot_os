defmodule Farmbot.Target.Network.WaitForTime do
  use Farmbot.Logger
  def start_link(_, _) do
    :ok = wait_for_time()
    Logger.success 3, "Time seems to be set: #{:os.system_time(:seconds)} . Moving on."
    :ignore
  end

  defp wait_for_time do
    case :os.system_time(:seconds) do
      t when t > 1534459652 ->
        :ok

      _ ->
        Process.sleep(1000)
        # Logger.warn "Waiting for time."
        wait_for_time()
    end
  end
end
