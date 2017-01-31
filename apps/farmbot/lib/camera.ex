defmodule Farmbot.Camera do
  @moduledoc """
    Test module for taking photos with the rpi camera.
  """

  # @params ["-o", "/tmp/image.jpg", "-e", "jpg", "-t", "1", "-w","1024", "-h", "1024"]
  # @command "raspistill"

  def params(path, extra_opts) do
    ~w"#{path}
    -d /dev/video0 -r 1280x720
    --no-banner --gmt
    --set sharpness=15
    --set gamma=10 --set contrast=75
    " ++ extra_opts
  end
  @command "fswebcam"
  # "fswebcam --save /tmp/image/image.jpg -d /dev/video0 -r 1280x720 --no-banner --gmt --skip 25 --set sharpness=15 --set gamma=10 --set contrast=75"
  require Logger

  def capture(path \\ nil, options \\ [])
  def capture(path, options) do
    path = path || out_path()
    System.cmd(@command, params(path, options))
    File.read!(path)
  end

  def out_path, do: "/tmp/images/#{Timex.now |> DateTime.to_unix(:milliseconds)}.jpg"

end
