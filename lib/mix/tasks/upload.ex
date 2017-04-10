if Code.ensure_loaded?(Mix.Tasks.Firmware.Push) do

  defmodule Mix.Tasks.Farmbot.Upload do
    @moduledoc false
    use Mix.Task
    alias Mix.Tasks.Firmware.Push
    @shortdoc "Uploads a file to a url"
    def run([ipaddr]) do
      otp_app = Mix.Project.config[:app]
      target = Mix.Project.config[:target]
      fw_file =
        if Mix.env == :prod do
          Path.join(["images", "#{Mix.env()}", "#{target}", "#{otp_app}-signed.fw"])
        else
          Path.join(["images", "#{Mix.env()}", "#{target}", "#{otp_app}.fw"])
        end

      unless File.exists?(fw_file) do
         Mix.raise "Could not find Firmware! Did you forget to produce a signed image?"
      end

      Push.run([ipaddr, "--firmware", "#{fw_file}", "--reboot", "true"])
    end
  end

else

  defmodule Mix.Tasks.Farmbot.Upload do
    @moduledoc false
    use Mix.Task
    @shortdoc "Uploads a file to a url"
    def run(_) do
      Mix.raise """
      Something in your environment is borked!
      """
    end
  end

end
