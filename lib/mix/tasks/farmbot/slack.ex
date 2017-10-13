defmodule Mix.Tasks.Farmbot.Slack do
  @moduledoc "Upload a file to slack. Requires a slack key env var."
  use Mix.Task
  alias Farmbot.{Context, HTTP}
  @shortdoc "Upload an image to farmbot slack."

  def run(opts) do
    Registry.start_link(:duplicate,  Farmbot.Registry)
    Application.ensure_all_started(:httpoison)

    {keywords, uhh, _} = opts |> OptionParser.parse(switches: [signed: :boolean])
    signed?          = Keyword.get(keywords, :signed, false)
    {:ok, _}         = Farmbot.DebugLog.start_link()
    ctx              = Context.new()
    {:ok, http}      = HTTP.start_link(ctx, [])
    ctx              = %{ctx | http: http}
    otp_app          = Mix.Project.config[:app]
    target           = Mix.Project.config[:target]
    commit           = Mix.Project.config[:commit]
    fw_file          = Path.join(["images", "#{Mix.env()}", "#{target}",
      (if signed?, do: "#{otp_app}-signed.fw", else: "#{otp_app}.fw")])

    unless File.exists?(fw_file) do
      Mix.raise "Could not find firmware: #{fw_file}"
    end

    token    = System.get_env("SLACK_TOKEN") || Mix.raise "Could not find SLACK_TOKEN"
    time     = format_date_time(File.stat!(fw_file))
    filename = "#{otp_app}-#{Mix.env()}-#{commit}#{if signed?, do: "-signed-", else: "-"}#{time}.fw"
    comment  = Enum.join(uhh, " ")

    Mix.shell.info [:green, "Uploading: #{filename} (#{fw_file})"]

    url       = "https://slack.com/api/files.upload"
    form_data = %{
      :file             => fw_file,
      "token"           => token,
      "channels"        => "embedded-systems",
      "filename"        => filename,
      "title"           => filename,
      "initial_comment" => """
      *New Farmbot Firmware!*
      > *_Env_*:       `#{Mix.env()}`
      > *_Target_*:    `#{target}`
      > *_Commit_*:    `#{commit}`
      > *_Time_*:      `#{time}`
      #{String.trim(comment)}
      """
    }
    payload = Enum.map(form_data, fn({key, val}) -> {key, val} end)
    real_payload = {:multipart, payload}
    headers = [
      {'User-Agent', 'Farmbot HTTP Adapter'}
    ]
    %{body: body} = HTTP.post!(ctx, url, real_payload, headers)
    ok?           = body |> Poison.decode!() |> Map.get("ok", false)
    notify_opts = ~w"""
    -u normal -i #{:code.priv_dir(otp_app)}/static/farmbot_logo.png -a farmbot_build
    """
    message = if ok?, do: "Upload completed", else: "Upload failed!"
    # System.cmd("notify-send", [notify_opts | ["Farmbot Uploader", message]] |> List.flatten())
  end

  defp format_date_time(%{mtime: {{yr,m,day}, {hr, min, sec}}}) do
    dt = %DateTime{
      hour: hr,
      year: yr,
      month: m,
      day: day,
      minute: min,
      second: sec,
      time_zone: "Etc/UTC",
      zone_abbr: "UTC",
      std_offset: 0,
      utc_offset: 0
    } |> Timex.local()
    "#{dt.year}-#{pad(dt.month)}-#{pad(dt.day)}_#{pad(dt.hour)}#{pad(dt.minute)}"
  end

  defp pad(int) do
    if int < 10, do: "0#{int}", else: "#{int}"
  end
end
