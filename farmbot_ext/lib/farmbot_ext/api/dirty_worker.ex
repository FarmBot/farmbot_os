defmodule FarmbotExt.API.DirtyWorker do
  @moduledoc "Handles uploading/downloading of data from the API."
  alias FarmbotCore.Asset.{Private, Repo}

  alias FarmbotExt.{API, API.DirtyWorker}
  import API.View, only: [render: 2]

  require Logger
  require FarmbotCore.Logger
  use GenServer
  @timeout 1

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
    Process.send_after(self(), :do_work, @timeout)
    {:ok, %{module: module}}
  end

  @impl GenServer
  def handle_info(:do_work, %{module: module} = state) do
    (Private.list_dirty(module) ++ Private.list_local(module))
    |> Enum.uniq()
    |> Enum.map(fn dirty -> work(dirty, module) end)

    Process.send_after(self(), :do_work, @timeout)
    {:noreply, state}
  end

  def work(dirty, module) do
    if module == FarmbotCore.Asset.Point do
      FarmbotCore.Logger.info(3, "#{__MODULE__} Point#{dirty.id}.y = #{dirty.y}")
    end

    case http_request(dirty, module) do
      # Valid data
      {:ok, %{status: s, body: body}} when s > 199 and s < 300 ->
        dirty |> module.changeset(body) |> handle_changeset(module)

      # Invalid data
      {:ok, %{status: s, body: %{} = body}} when s > 399 and s < 500 ->
        FarmbotCore.Logger.error(2, "HTTP Error #{s}. #{inspect(body)}")
        changeset = module.changeset(dirty)

        Enum.reduce(body, changeset, fn {key, val}, changeset ->
          Ecto.Changeset.add_error(changeset, key, val)
        end)
        |> handle_changeset(module)

      # Invalid data, but the API didn't say why
      {:ok, %{status: s, body: _body}} when s > 399 and s < 500 ->
        FarmbotCore.Logger.error(2, "HTTP Error #{s}. #{inspect(dirty)}")

        module.changeset(dirty)
        |> Map.put(:valid?, false)
        |> handle_changeset(module)

      # HTTP Error. (500, network error, timeout etc.)
      error ->
        FarmbotCore.Logger.error(
          2,
          "[#{module} #{dirty.local_id} #{inspect(self())}] HTTP Error: #{module} #{
            inspect(error)
          }"
        )
    end
  end

  # If the changeset was valid, update the record.
  def handle_changeset(%{valid?: true} = changeset, _module) do
    Private.mark_clean!(Repo.update!(changeset))
    :ok
  end

  def handle_changeset(%{valid?: false, data: data} = changeset, module) do
    message =
      Enum.map(changeset.errors, fn
        {key, {msg, _meta}} when is_binary(key) -> "\t#{key}: #{msg}"
        {key, msg} when is_binary(key) -> "\t#{key}: #{msg}"
      end)
      |> Enum.join("\n")

    FarmbotCore.Logger.error(3, "Failed to sync: #{module} \n #{message}")
    _ = Repo.delete!(data)
    :ok
  end

  defp http_request(%{id: nil} = dirty, module) do
    path = module.path()
    data = render(module, dirty)
    API.post(API.client(), path, data)
  end

  defp http_request(dirty, module) when module in @singular do
    path = path = module.path()
    data = render(module, dirty)
    API.patch(API.client(), path, data)
  end

  defp http_request(dirty, module) do
    path = Path.join(module.path(), to_string(dirty.id))
    data = render(module, dirty)
    API.patch(API.client(), path, data)
  end
end
