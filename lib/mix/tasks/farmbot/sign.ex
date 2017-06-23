defmodule Mix.Tasks.Farmbot.Sign do
  @moduledoc false
  use Mix.Task
  @shortdoc "Signs a fw image"

  def run(args) do
    otp_app = Mix.Project.config[:app]
    target = Mix.Project.config[:target]
    fw_file = Path.join(["images", "#{Mix.env()}", "#{target}", "#{otp_app}.fw"])

    case args do
      [priv_key_file, out_file] ->
        do_run(priv_key_file, fw_file, out_file)
      [priv_key_file] ->
        out_file = Path.join(["images", "#{Mix.env()}", "#{target}", "#{otp_app}-signed.fw"])
        do_run(priv_key_file, fw_file, out_file)
      _ -> Mix.raise("""
      Usage: mix farmbot.sign /tmp/fwup-key.priv /tmp/outputfile-signed.fw
      """)
    end
  end


  defp do_run(priv_key_file, unsigned_file, out_file) do
    Mix.shell.info [:green, "Signing: #{unsigned_file} with: #{priv_key_file} to: #{out_file}"]
    unless File.exists?(unsigned_file) do
       Mix.raise "Could not find Firmware!"
    end
    System.cmd("fwup", ["-S", "-s", priv_key_file, "-i", unsigned_file, "-o", out_file])
  end
end
