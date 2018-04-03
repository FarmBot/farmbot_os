defmodule Farmbot.Repo do
  use Ecto.Repo,
    otp_app: :farmbot,
    adapter: Application.get_env(:farmbot, __MODULE__)[:adapter]

  defdelegate sync(full \\ false), to: Farmbot.Repo.Worker
  defdelegate await_sync, to: Farmbot.Repo.Worker
  defdelegate register_sync_cmd(id, kind, body), to: Farmbot.System.ConfigStorage.SyncCmd

  # A partial sync pulls all the sync commands from storage,
  # And applies them one by one.
  def partial_sync do
    :ok
  end

  @doc """
  A full sync will clear the entire local data base
  and then redownload all data.
  """
  def full_sync do
    Logger.debug 3, "Starting full sync."

  end

  defp do_http_parts do

  end
end
