defmodule Mix.Tasks.Farmbot.Env do
  @moduledoc false

  @doc false
  def mix_config(key \\ nil) do
    config = Mix.Project.config()
    if key do
      config[key]
    else
      config
    end
  end

  @doc false
  def fw_file do
    # Path.join([images_dir(), "test.fw"])
    Path.join([images_dir(), "#{mix_config(:app)}.fw"])
  end

  @doc false
  def signed_fw_file do
    Path.join([images_dir(), "#{mix_config(:app)}-signed.fw"])
  end

  @doc false
  def images_dir do
    Path.join([mix_config(:build_path), env(), "nerves", "images"])
  end

  @doc false
  def target do
    mix_config(:target)
  end

  @doc false
  def env do
    to_string(Farmbot.Project.env())
  end

  @doc false
  def format_date_time(%{ctime: {{yr, m, day}, {hr, min, sec}}}) do
    dt =
      %DateTime{
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
      }
      |> Timex.local()

    "#{dt.year}-#{pad(dt.month)}-#{pad(dt.day)}_#{pad(dt.hour)}#{pad(dt.minute)}"
  end

  defp pad(int) do
    if int < 10, do: "0#{int}", else: "#{int}"
  end

  @doc false
  def build_comment(time, comment) do
    """
    *New Farmbot Firmware!*
    > *_Env_*:       `#{env()}`
    > *_Target_*:    `#{target()}`
    > *_Version_*:   `#{mix_config(:version)}`
    > *_Commit_*:    `#{mix_config(:commit)}`
    > *_Time_*:      `#{time}`
    #{String.trim(comment)}
    """
  end

  @doc false
  def slack_token do
    System.get_env("SLACK_TOKEN") || Mix.raise "No $SLACK_TOKEN environment variable."
  end
end
