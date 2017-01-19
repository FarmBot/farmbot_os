defmodule Farmbot.System.Updates do
  @moduledoc """
    Check, download, apply updates
  """

  @releases_url "https://api.github.com/repos/farmbot/farmbot_os/releases"
  @headers ["User-Agent": "FarmbotOS"]
  @target Mix.Project.config()[:target]
  @path "/tmp/update.fw"
  require Logger

  # TODO(connor): THIS IS A MINOR IMPROVEMENT FROM THE LAST VERSION OF THIS FILE,
  # BUT IT DEFINATELY NEEDS FURTHER REFACTORING.

  @spec mod(atom) :: atom
  defp mod(target), do: Module.concat([Farmbot, System, target, Updates])

  @doc """
    Checks for updates, and if there is an update, downloads, and applies it.
  """
  @spec check_and_download_updates() :: :ok | {:error, term} | :no_updates
  def check_and_download_updates() do
    case check_updates() do
      {:update, url} ->
        Logger.debug ">> has found a new Operating System update!"
        install_updates(url)
      :no_updates ->
        Logger.debug ">> is already on the latest Operating System version!"
        :no_updates
      {:error, reason} ->
        Logger.error ">> encountered an error checking for updates! #{reason}"
        {:error, reason}
    end
  end

  @doc """
    Checks for updates
  """
  @spec check_updates() :: {:update, String.t} | :no_updates | {:error, term}
  def check_updates() do
    case HTTPoison.get(@releases_url <> "/latest", @headers) do
       %HTTPoison.Response{body: body, status_code: 200} ->
         json = Poison.decode!(body)
         version = json["tag_name"]
         version_without_v = String.trim_leading version, "v"
         url = "https://github.com/FarmBot/farmbot_os/releases/download/#{version}/farmbot-#{@target}-#{version_without_v}.fw"
         {:update, url}
       {:error, %HTTPoison.Error{reason: reason}} -> {:error, reason}
       error -> {:error, error}
    end
  end

  @doc """
    Installs an update from a url
  """
  @spec install_updates(String.t) :: no_return
  def install_updates(url) do
    # Ignore the compiler warning here.
    # "I'll fix it later i promise" -- Connor Rigby
    path = Downloader.run(url, @path)
    mod(@target).install(path)
    Farmbot.System.reboot()
  end
end
