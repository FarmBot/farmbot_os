defmodule FarmbotExt.API.DirtyWorker do
  @moduledoc "Handles uploading/downloading of data from the API."
  alias FarmbotCore.Asset.{Private, Repo}

  alias FarmbotExt.{API, API.DirtyWorker}
  import API.View, only: [render: 2]

  require Logger
  use GenServer
  @timeout 10000

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
    # Logger.disable(self())
    module = Keyword.fetch!(args, :module)
    timeout = Keyword.get(args, :timeout, @timeout)
    {:ok, %{module: module, timeout: timeout}, timeout}
  end

  @impl GenServer
  def handle_info(:timeout, %{module: module} = state) do
    dirty = Private.list_dirty(module)
    local = Private.list_local(module)
    {:noreply, state, {:continue, Enum.uniq(dirty ++ local)}}
  end

  @impl GenServer
  def handle_continue([], state) do
    {:noreply, state, state.timeout}
  end

  def handle_continue([dirty | rest], %{module: module} = state) do
    Logger.info("[#{module} #{dirty.local_id} #{inspect(self())}] Handling dirty data")

    case http_request(dirty, state) do
      # Valid data
      {:ok, %{status: s, body: body}} when s > 199 and s < 300 ->
        Logger.debug(
          "[#{module} #{dirty.local_id} #{inspect(self())}] HTTP request complete: #{s} ok"
        )

        dirty |> module.changeset(body) |> handle_changeset(rest, state)

      # Invalid data
      {:ok, %{status: s, body: %{} = body}} when s > 399 and s < 500 ->
        Logger.debug(
          "[#{module} #{dirty.local_id} #{inspect(self())}] HTTP request complete: #{s} error+body"
        )

        changeset = module.changeset(dirty)

        Enum.reduce(body, changeset, fn {key, val}, changeset ->
          Ecto.Changeset.add_error(changeset, key, val)
        end)
        |> handle_changeset(rest, state)

      # Invalid data, but the API didn't say why
      {:ok, %{status: s, body: _body}} when s > 399 and s < 500 ->
        Logger.debug(
          "[#{module} #{dirty.local_id} #{inspect(self())}] HTTP request complete: #{s} error"
        )

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
    Logger.info("Successfully synced: #{state.module}", changeset: changeset)

    Repo.update!(changeset)
    |> Private.mark_clean!()

    {:noreply, state, {:continue, rest}}
  end

  # If the changeset was invalid, delete the record.
  # TODO(Connor) - Update the dirty field here, upload to rollbar?
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
    Logger.debug("#{state.module} clean request (post)")
    path = state.module.path()
    data = render(state.module, dirty)
    API.post(API.client(), path, data)
  end

  defp http_request(dirty, state) do
    Logger.debug("#{state.module} dirty request (patch)")
    path = state.module.path()
    data = render(state.module, dirty)
    API.patch(API.client(), path, data)
  end
end
