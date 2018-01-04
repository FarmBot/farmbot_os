defmodule Mix.Tasks.Farmbot.ProdImage do
  @moduledoc "Build a production firmware image file"
  @shortdoc @moduledoc

  use Mix.Task
  import Mix.Tasks.Farmbot.Env

  def run(opts) do
    {keywords, _, _} =
      opts |> OptionParser.parse(switches: [signed: :boolean])

    signed? = Keyword.get(keywords, :signed, false)
    Application.ensure_all_started(:timex)

    fw_file_to_upload = if signed?, do: signed_fw_file(), else: fw_file()
    time = format_date_time(File.stat!(fw_file_to_upload))

    filename =
      "#{mix_config(:app)}-#{target()}-#{env()}-#{mix_config(:commit)}#{
        if signed?, do: "-signed-", else: "-"
      }#{time}.img"
    Mix.shell().info(build_comment(time, ""))
    Mix.Tasks.Firmware.Image.run([filename])
  end
end
