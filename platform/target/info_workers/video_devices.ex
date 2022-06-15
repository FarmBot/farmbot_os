defmodule FarmbotOS.Platform.Target.InfoWorker.VideoDevices do
  @moduledoc """
  Worker responsible for listing available camera devices.
  """

  use GenServer
  @default_timeout_ms 60_000
  @error_timeout_ms 5_000

  alias FarmbotOS.BotState

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init([]) do
    {:ok, nil, 0}
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    {:ok, result} = File.ls("/dev")

    video_devices =
      result
      |> Enum.filter(fn s -> String.starts_with?(s, "video") end)
      |> Enum.map(fn s -> String.replace(s, "video", "") end)
      |> Enum.join(",")

    if GenServer.whereis(BotState) do
      :ok = BotState.report_video_devices(video_devices)
      {:noreply, state, @default_timeout_ms}
    else
      {:noreply, state, @error_timeout_ms}
    end
  end
end
