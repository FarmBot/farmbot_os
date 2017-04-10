defmodule Mix.Tasks.Farmbot.Sign do
  @moduledoc false
  use Mix.Task
  @shortdoc "Signs a fw image"

  def run([priv_key_path, out_file_path]) do
    otp_app = Mix.Project.config[:app]
    target = Mix.Project.config[:target]
    fw_file = Path.join(["images", "#{Mix.env()}", "#{target}", "#{otp_app}.fw"])
    Mix.shell.info [:green, "Signing: #{fw_file} with: #{priv_key_path} to: #{out_file_path}"]
    unless File.exists?(fw_file) do
       raise "Could not find Firmware!"
    end
    System.cmd("fwup", ["-S", "-s", priv_key_path, "-i", fw_file, "-o", out_file_path])
  end
end
