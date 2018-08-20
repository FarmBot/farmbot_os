defmodule Farmbot.HTTP do
  import Farmbot.Config, only: [get_config_value: 3]
  import Farmbot.HTTP.Helpers, only: [fadr: 2]
  alias Farmbot.Asset.{
    Device,
    FarmEvent,
    FarmwareEnv,
    FarmwareInstallation,
    Peripheral,
    PinBinding,
    Point,
    Regimen,
    Sensor,
    Sequence,
    Tool,
  }

  use Tesla, docs: false
  @version Farmbot.Project.version()
  @target Farmbot.Project.target()

  plug Tesla.Middleware.JSON, engine: Farmbot.JSON
  plug Tesla.Middleware.FollowRedirects, max_redirects: 10
  plug Tesla.Middleware.Logger, log_level: :info

  fadr :device, Device
  fadr :farm_events, FarmEvent
  fadr :farmware_installations, FarmwareInstallation
  fadr :farmware_envs, FarmwareEnv
  fadr :peripherals, Peripheral
  fadr :pin_bindings, PinBinding
  fadr :points, Point
  fadr :regimens, Regimen
  fadr :sensors, Sensor
  fadr :sequences, Sequence
  fadr :tools, Tool

  def firmware_config do
    client()
    |> get!("/api/firmware_config")
    |> Map.fetch!(:body)
  end

  def update_firmware_config(%{} = data) do
    client()
    |> patch!("/api/firmware_config", data)
  end

  def fbos_config do
    client()
    |> get!("/api/fbos_config")
    |> Map.fetch!(:body)
  end

  @doc "Upload a file to Farmbot GCS."
  def upload_file(filename, meta) do
    client()
    |> get!("/api/storage_auth")
    |> finish_upload(filename, meta)
  end

  defp finish_upload(%{status: 200, body: body, url: beep}, filename, meta) do
    # Farmbot API doesn't supply the scheme
    # So we extract it from the previous http request url.
    url = URI.parse(beep).scheme <> ":" <> body["url"] |> IO.inspect(label: "url")
    form_data = body["form_data"]
    attachment_url = url <> form_data["key"]

    alias Tesla.Multipart
    mp = Enum.reduce(form_data, Multipart.new(), fn({key, v}, mp) ->
      case key do
        "file" ->
          Multipart.add_file(mp, filename, name: "file")
        _ ->
          Multipart.add_field(mp, key, v)
      end
    end)

    # Post the image to GCS.
    post!(url, mp)
    body = %{"attachment_url" => attachment_url, "meta" => meta}
    post!(client(), "/api/images", body)
  end

  defp fetch_and_decode(url, kind) do
    client()
    |> get!(url)
    |> Map.fetch!(:body)
    |> Farmbot.Asset.to_asset(kind)
  end

  def client do
    token = get_config_value(:string, "authorization", "token")
    server = get_config_value(:string, "authorization", "server")
    headers = [
      {"authorization", "token: " <> token},
      {"user-agent", "FarmbotOS/#{@version} (#{@target}) #{@target} ()"}
    ]
    Tesla.build_client [
      {Tesla.Middleware.BaseUrl, server},
      {Tesla.Middleware.Headers, headers}
    ]
  end
end
