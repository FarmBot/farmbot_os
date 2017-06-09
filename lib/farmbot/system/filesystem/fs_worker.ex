defmodule Farmbot.System.FS.Worker do
  @moduledoc """
    Pulls transactions from the queue, does them, etc.
  """

  # NOTE(Connor) This isn't working the way i want it to, but i dont have time
  # to fix it right now.
  # Expected behavior is for this module to get the list of transactions,
  # make the filesystem read-write, do all the things
  # and then make the fs read-only again.
  # What actually happens is it grabs them one at a time for some reason
  # Either way this seems to have fixed the race condition waiting for
  # teh transaction and mucking up state.

  require Logger
  use GenStage
  alias Farmbot.Context

  def start_link(%Context{} = _ctx, target, opts) do
    GenStage.start_link(__MODULE__, target, opts)
  end

  def init(target) do
    mod = Module.concat([Farmbot, System, target, FileSystem])
    {:consumer, mod, subscribe_to: [Farmbot.System.FS]}
  end

  def handle_events(events, _from, mod) do
    mod.mount_read_write
    for {transaction, cb} <- events do
      transaction.()
      if is_pid(cb) do
        send cb, {:ok, :ok}
      else
        :ok
      end
    end
    mod.mount_read_only
    {:noreply, [], mod}
  end

  def handle_call(:get_state, _, state), do: {:reply, [], state, state}

  def terminate(_, mod) do
    mod.mount_read_only
    :ok
  end
end
