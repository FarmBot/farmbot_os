defmodule Farmbot.Repo.Worker do
  @moduledoc "Handles syncing and caching of HTTP data."

  use GenServer
  alias Farmbot.System.ConfigStorage
  import ConfigStorage, only: [get_config_value: 3]
  import Farmbot.BotState, only: [set_sync_status: 1]
  use Farmbot.Logger

  # This allows for the sync to gracefully timeout
  # before terminating the GenServer.
  @gen_server_timeout_grace 1500
  # 30 minutes.
  @default_stability_timeout 1.7e+6 |> round()
  # @default_stability_timeout 1500

  @doc "Sync Farmbot with the Web APP."
  def sync(verbosity \\ 1) do
    timeout = sync_timeout()

    GenServer.call(
      __MODULE__,
      {:sync, [verbosity, timeout]},
      timeout + @gen_server_timeout_grace
    )
  end

  @doc "Waits for a sync to complete if one is happening."
  def await_sync do
    GenServer.call(
      __MODULE__,
      :await_sync,
      sync_timeout() + @gen_server_timeout_grace
    )
  end

  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defmodule State do
    @moduledoc false
    defstruct waiting: [],
              requires_full: false,
              stability_timer: nil,
              syncing: false,
              sync_ref: nil,
              sync_timer: nil,
              sync_pid: nil
  end

  def init([]) do
    set_sync_status(:sync_now)
    stability_timer = refresh_or_start_stability_timeout(nil, self())

    if get_config_value(:bool, "settings", "auto_sync") do
      pid = spawn(Farmbot.Repo, :full_sync, [1])
      ref = Process.monitor(pid)
      timer = refresh_or_start_sync_timeout(nil, sync_timeout(), ref, self())
      set_sync_status(:syncing)

      {:ok,
       struct(State, %{
         stability_timer: stability_timer,
         sync_pid: pid,
         sync_ref: ref,
         sync_timer: timer,
         waiting: [],
         syncing: true
       })}
    else
      {:ok, struct(State, %{stability_timer: stability_timer, requires_full: true})}
    end
  end

  def terminate(_, _) do
    :ok
  end

  def handle_call(:await_sync, from, %{syncing: true} = state) do
    {:noreply, %{state | waiting: [from | state.waiting]}}
  end

  def handle_call(:await_sync, _from, state) do
    {:reply, :ok, state}
  end

  # If a sync is already happening, just add our ref to the pool of waiting.
  def handle_call({:sync, [_, _]}, from, %{syncing: true} = state) do
    {:noreply, %{state | waiting: [from | state.waiting]}}
  end

  def handle_call(
        {:sync, [verbosity, timeout_ms]},
        from,
        %State{requires_full: false} = state
      ) do
    pid = spawn(Farmbot.Repo, :fragment_sync, [verbosity])
    ref = Process.monitor(pid)

    timer = refresh_or_start_sync_timeout(state.sync_timer, timeout_ms, ref, self())

    set_sync_status(:syncing)

    {:noreply,
     %{
       state
       | sync_pid: pid,
         sync_ref: ref,
         sync_timer: timer,
         waiting: [from | state.waiting],
         syncing: true
     }}
  end

  def handle_call(
        {:sync, [verbosity, timeout_ms]},
        from,
        %State{requires_full: true} = state
      ) do
    pid = spawn(Farmbot.Repo, :full_sync, [verbosity])
    ref = Process.monitor(pid)

    timer = refresh_or_start_sync_timeout(state.sync_timer, timeout_ms, ref, self())

    set_sync_status(:syncing)

    {:noreply,
     %{
       state
       | sync_pid: pid,
         sync_ref: ref,
         sync_timer: timer,
         waiting: [from | state.waiting],
         syncing: true
     }}
  end

  # The sync process has taken too long.
  def handle_info({:sync_timeout, sync_ref}, %{sync_ref: sync_ref} = state) do
    Logger.error(1, "Sync timed out!")
    reply_waiting(state.waiting, {:error, :sync_timeout})
    set_sync_status(:sync_error)

    {:noreply,
     %{
       state
       | requires_full: true,
         waiting: [],
         sync_ref: nil,
         sync_pid: nil,
         syncing: false,
         sync_timer: nil
     }}
  end

  # Ignore timeouts that didn't get canceled for whatever reason.
  def handle_info({:sync_timeout, _old_ref}, state) do
    Logger.warn(1, "Got unexpected sync timeout.")
    {:noreply, state}
  end

  def handle_info(:stability_timeout, state) do
    if !state.requires_full do
      Logger.debug(3, "Next sync will be a full sync.")
    end

    {:noreply,
     %{
       state
       | requires_full: true,
         stability_timer: refresh_or_start_stability_timeout(state.stability_timer, self())
     }}
  end

  # The sync process exited before the timeout normally.
  def handle_info(
        {:DOWN, ref, :process, pid, :normal},
        %{sync_ref: ref, sync_pid: pid} = state
      ) do
    reply_waiting(state.waiting, :ok)
    maybe_cancel_timer(state.sync_timer)
    set_sync_status(:synced)

    {:noreply,
     %{
       state
       | requires_full: false,
         waiting: [],
         sync_ref: nil,
         sync_pid: nil,
         syncing: false,
         sync_timer: nil
     }}
  end

  # The sync process exited after the timeout erronously.
  def handle_info(
        {:DOWN, ref, :process, pid, reason},
        %{sync_ref: ref, sync_pid: pid} = state
      ) do
    reply_waiting(state.waiting, reason)
    maybe_cancel_timer(state.sync_timer)
    set_sync_status(:sync_error)

    {:noreply,
     %{
       state
       | requires_full: true,
         waiting: [],
         sync_ref: nil,
         sync_pid: nil,
         syncing: false,
         sync_timer: nil
     }}
  end

  # Happens if the sync completes _after_ a timeout.
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.error(1, "Sync completed after timing out: #{inspect(reason)}")

    {:noreply,
     %{
       state
       | requires_full: true,
         waiting: [],
         sync_ref: nil,
         sync_pid: nil,
         syncing: false,
         sync_timer: nil
     }}
  end

  defp sync_timeout do
    get_config_value(:float, "settings", "sync_timeout_ms") |> round()
  end

  defp refresh_or_start_sync_timeout(old_timer, timeout_ms, sync_ref, pid) do
    maybe_cancel_timer(old_timer)
    Process.send_after(pid, {:sync_timeout, sync_ref}, timeout_ms)
  end

  defp refresh_or_start_stability_timeout(old_timer, pid) do
    maybe_cancel_timer(old_timer)
    Process.send_after(pid, :stability_timeout, @default_stability_timeout)
  end

  defp maybe_cancel_timer(old_timer) do
    if old_timer && Process.read_timer(old_timer) do
      Process.cancel_timer(old_timer)
    end
  end

  defp reply_waiting(list, msg) do
    for from <- list do
      :ok = GenServer.reply(from, msg)
    end
  end
end
