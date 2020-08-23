defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false
  require FarmbotCore.Logger

  def check_update() do
    target = get_target()
    meta_data = download_meta_data(target)
    install_update(Map.fetch!(meta_data, "image_url"))
    # Probably never returns?
    :ok
  end

  def get_target(), do: "WIP"
  def download_meta_data(_target), do: %{"image_url" => "WIP"}

  def install_update(url) do
    path = "/tmp/fw#{trunc(:random.uniform() * 10000)}.fw"

    {:ok, :saved_to_file} =
      :httpc.request(:get, {to_charlist(url), []}, [], stream: to_charlist(path))

    args = [
      "-a",
      "-i",
      path,
      "-d",
      "/dev/mmcblk0",
      "-t",
      "upgrade"
    ]

    {_, 0} = System.cmd("fwup", args)
    FarmbotCeleryScript.SysCalls.reboot()
  end
end
