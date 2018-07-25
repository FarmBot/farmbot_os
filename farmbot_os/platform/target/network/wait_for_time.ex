defmodule Farmbot.Target.Network.WaitForTime do
  require Farmbot.Logger
  nerves_time = case Nerves.Time.FileTime.time() do
    {:error, _} -> NaiveDateTime.utc_now()
    ndt -> ndt
  end
  @nerves_time nerves_time

  def start_link(_, _) do
    :ok = wait_for_time()
    Farmbot.Logger.success 3, "Time seems to be set. Moving on."
    IO.puts "Check: #{inspect(@nerves_time)}"
    IO.puts "Current: #{inspect(NaiveDateTime.utc_now())}"
    :ignore
  end

  # • -1 -- the first date comes before the second one
  # • 0  -- both arguments represent the same date when coalesced to the same
  #   timezone.
  # • 1  -- the first date comes after the second one

  defp wait_for_time do
    case Timex.compare(NaiveDateTime.utc_now(), get_file_time()) do
      1 -> :ok
      _ ->
        Process.sleep(1000)
        # Logger.warn "Waiting for time."
        wait_for_time()
    end
  end

  def get_file_time, do: @nerves_time
end
