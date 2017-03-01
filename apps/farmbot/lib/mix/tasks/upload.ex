defmodule Mix.Tasks.Farmbot.Upload do
  @moduledoc false
  use Mix.Task
  alias Mix.Tasks.Firmware.Push
  @shortdoc "Uploads a file to a url"
  def run(args) do
    otp_app = Mix.Project.config[:app]
    target = Mix.Project.config[:target]
    # TODO(Connor) change this back when nerves is stable again
    # img_path = Mix.Project.config[:images_path]
    # fw_file = Path.join(img_path, "#{otp_app}.fw")
    fw_file = Path.join(["_images", "#{target}", "#{otp_app}.fw"])
    unless File.exists?(fw_file) do
       raise "Could not find Firmware!"
    end
    ip_address = List.first(args)
    Push.run([ip_address, "--firmware", "#{fw_file}", "--reboot", "true"])
  end
end
