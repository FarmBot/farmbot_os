defmodule Farmbot.Camera do
  @moduledoc """
    Test module for taking photos with the rpi camera.
  """
  # @params ["-o", "/tmp/image.jpg", "-e", "jpg", "-t", "1", "-w","1024", "-h", "1024"]
  # @command "raspistill"

  @params ~w"/tmp/image.jpg -d /dev/video0 -r 1280x720 --no-banner --gmt --skip 25 --set sharpness=15 --set gamma=10 --set contrast=75"
  @command "fswebcam"
  # "fswebcam --save /tmp/image.jpg -d /dev/video0 -r 1280x720 --no-banner --gmt --skip 25 --set sharpness=15 --set gamma=10 --set contrast=75"
  require Logger

  def ls do
    {f, _} = System.cmd("ls", ["-lah", "/tmp"])
    IO.puts f
  end

  def capture, do: System.cmd(@command, @params)

  def get_form_data_auth do
    req = Farmbot.HTTP.get "/api/storage_auth"
    req.body |> Poison.decode!
  end

  def blah do
    req = Farmbot.HTTP.get("/api/storage_auth")
    f = Poison.decode!(req.body)
    url = "https:" <> f["url"]
    form_data = f["form_data"]
    binary = File.read!("/tmp/image.jpg")
    payload =
      Enum.map(form_data, fn({key, value}) ->
        if key == "file", do: {"file", binary}, else:  {key, value}
      end)

    headers = [
      {"Content-Type", "multipart/form-data"},
      {"User-Agent", "FarmbotOS"}
    ]
    Logger.debug "URL: #{url}"
    Logger.debug "Payload: #{inspect payload}"
    Logger.debug "Headers: #{inspect headers}"

    blah = HTTPoison.post(url, {:multipart, payload}, headers)
    Logger.debug "THIS THING HERE: #{inspect blah}"
    attachment_url = url<>form_data["key"]
    Logger.debug "here: #{attachment_url}"

    json = Poison.encode!(
      %{"attachment_url" => attachment_url, "meta" => %{x: 1, y: 1, z: 1}}
      )

    Farmbot.HTTP.post "/api/images", json
  end

end
