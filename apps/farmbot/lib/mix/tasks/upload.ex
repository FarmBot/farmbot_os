defmodule Mix.Tasks.Farmbot.Upload do
  use Mix.Task
  alias Mix.Tasks.Firmware.Push
  @shortdoc "Uploads a file to a url"
  def run(args) do
    img_path = Mix.Project.config[:images_path]
    fw_file = Path.join(img_path, "farmbot.fw")
    unless File.exists?(fw_file) do
       raise "Could not find Firmware!"
    end
    ip_address = List.first(args)
    Push.run([ip_address, "--firmware", "#{fw_file}", "--reboot", "true"])
  end
end
