defmodule Farmbot.FarmwareRuntime.PlugWrapper do
  @moduledoc "Puts a `FarmwareInstallationManifest` in the private of each call"
  @behaviour Plug
  alias Farmbot.FarmwareRuntime.Router
  import Plug.Conn

  def init(opts) do
    manifest = Keyword.fetch!(opts, :manifest)
    runtime_pid = Keyword.fetch!(opts, :runtime_pid)
    %{manifest: manifest, runtime_pid: runtime_pid}
  end

  def call(conn, runtime_info) do
    put_private(conn, :runtime_info, runtime_info)
    |> Router.call([])
  end
end
