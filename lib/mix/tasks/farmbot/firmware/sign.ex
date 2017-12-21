defmodule Mix.Tasks.Farmbot.Firmware.Sign do
  @moduledoc "Sign a firmware."
  @shortdoc "Sign a firmware."
  import Mix.Tasks.Farmbot.Env

  use Mix.Task

  def run(args) do
    case args do
      [private_key_file, input_fw_file, output_fw_file] ->
        do_run(private_key_file, input_fw_file, output_fw_file)
      [private_key_file] ->
        do_run(private_key_file, fw_file(), signed_fw_file())
      _ -> error()
    end
  end

  defp error do
    Mix.raise "Usage: mix farmbot.firmware.sign /path/to/private/key [input.fw] [output.fw]"
  end

  defp do_run(private_key_file, input_fw_file, output_fw_file) do
    unless File.exists?(private_key_file) do
      error()
    end

    unless File.exists?(input_fw_file) do
      Mix.raise "Could not find input file: #{input_fw_file}"
    end

    Mix.shell.info [:green, "Signing: #{input_fw_file} with: #{private_key_file} to: #{output_fw_file}"]

    System.cmd("fwup", ["-S", "-s", private_key_file, "-i", input_fw_file, "-o", output_fw_file])
  end
end
