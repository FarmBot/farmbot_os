defmodule FarmbotExt.API.DirtyWorker do
  @moduledoc "Handles uploading/downloading of data from the API."
  alias FarmbotCore.Asset.{Private, Repo}

  alias FarmbotExt.{API, API.DirtyWorker}
  import API.View, only: [render: 2]

  require Logger
  use GenServer
  @timeout 10000

  # these resources can't be accessed by `id`.
  @singular [
    FarmbotCore.Asset.Device,
    FarmbotCore.Asset.FirmwareConfig,
    FarmbotCore.Asset.FbosConfig
  ]

  @doc false
  def child_spec(module) when is_atom(module) do
    %{
      id: {DirtyWorker, module},
      start: {__MODULE__, :start_link, [[module: module, timeout: @timeout]]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc "Start an instance of a DirtyWorker"
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    module = Keyword.fetch!(args, :module)
    timeout = Keyword.get(args, :timeout, @timeout)
    timer = Process.send_after(self(), :timeout, timeout)
    {:ok, %{module: module, timeout: timeout, timer: timer}}
  end

  @impl GenServer
  def handle_info(:timeout, %{module: module} = state) do
    dirty = Private.list_dirty(module)
    local = Private.list_local(module)
    {:noreply, state, {:continue, Enum.uniq(dirty ++ local)}}
  end

  @impl GenServer
  def handle_continue([], state) do
    timer = Process.send_after(self(), :timeout, state.timeout)
    {:noreply, %{state | timer: timer}}
  end

  def handle_continue([dirty | rest], %{module: module} = state) do
    case http_request(dirty, state) do
      # Valid data
      {:ok, %{status: s, body: body}} when s > 199 and s < 300 ->
        dirty |> module.changeset(body) |> handle_changeset(rest, state)

      # Invalid data
      {:ok, %{status: s, body: %{} = body}} when s > 399 and s < 500 ->
        changeset = module.changeset(dirty)

        Enum.reduce(body, changeset, fn {key, val}, changeset ->
          Ecto.Changeset.add_error(changeset, key, val)
        end)
        |> handle_changeset(rest, state)

      # Invalid data, but the API didn't say why
      {:ok, %{status: s, body: _body}} when s > 399 and s < 500 ->
        module.changeset(dirty)
        |> Map.put(:valid?, false)
        |> handle_changeset(rest, state)

      # HTTP Error. (500, network error, timeout etc.)
      error ->
        Logger.error(
          "[#{module} #{dirty.local_id} #{inspect(self())}] HTTP Error: #{state.module} #{
            inspect(error)
          }"
        )

        {:noreply, state, @timeout}
    end
  end

  # If the changeset was valid, update the record.
  def handle_changeset(%{valid?: true} = changeset, rest, state) do
    Repo.update!(changeset)
    |> Private.mark_clean!()

    {:noreply, state, {:continue, rest}}
  end

  def handle_changeset(%{valid?: false, data: data} = changeset, rest, state) do
    message =
      Enum.map(changeset.errors, fn
        {key, {msg, _meta}} when is_binary(key) -> "\t#{key}: #{msg}"
        {key, msg} when is_binary(key) -> "\t#{key}: #{msg}"
      end)
      |> Enum.join("\n")

    Logger.error("Failed to sync: #{state.module} \n #{message}")
    _ = Repo.delete!(data)
    {:noreply, state, {:continue, rest}}
  end

  defp http_request(%{id: nil} = dirty, state) do
    path = state.module.path()
    data = render(state.module, dirty)
    API.post(API.client(), path, data)
  end

  defp http_request(dirty, %{module: module} = state) when module in @singular do
    path = path = state.module.path()
    data = render(state.module, dirty)
    API.patch(API.client(), path, data)
  end

  defp http_request(dirty, state) do
    path = Path.join(state.module.path(), to_string(dirty.id))
    data = render(state.module, dirty)
    API.patch(API.client(), path, data)
  end
end
