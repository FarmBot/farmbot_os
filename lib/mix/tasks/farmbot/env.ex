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
  def slack_token do
    System.get_env("SLACK_TOKEN") || Mix.raise "No $SLACK_TOKEN environment variable."
  end
end
