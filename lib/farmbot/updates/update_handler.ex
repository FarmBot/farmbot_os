defmodule Farmbot.Updates.Handler do
  require Logger
  @moduledoc """
    Bunch of stuff to do updates.
  """

  @type update_output
  :: {:update, String.t | nil}
  | {:error,  String.t | atom}
  | :no_updates

  @doc """
    Another shortcut for the shorcut
  """
  @spec check_and_download_updates(:os | :fw)
  :: :ok | {:error, atom} | :no_updates
  def check_and_download_updates(something) do
    Logger.debug ">> Is checking for updates."
    case check_updates(something) do
      {:error, reason} ->
        Logger.debug ">> encountered an error checking for updates: #{inspect reason}."
      {:update, url} ->
        install_update(something, url)
      :no_updates ->
        Logger.debug(">> is already on the latest operating system version.",
          channels: [:toast], type: :success)
    end
  end

  @spec install_update(:os | :fw, String.t) :: :ok | {:error, atom}
  defp install_update(:os, url) do
    # This is where the actual download and update happens.
    Logger.debug ">> found an operating system update. "
    File.rm("/tmp/update.fw")
    Downloader.run(url, "/tmp/update.fw") |> Nerves.Firmware.upgrade_and_finalize
    Logger.warn ">> is going down for an operating system update!", channels: [:toast]
    Process.sleep(5000)
    Nerves.Firmware.reboot
  end

  defp install_update(:fw, url) do
    Logger.debug ">> found a firmware update!"
    File.rm("/tmp/update.hex")
    file = Downloader.run(url, "/tmp/update.hex")
    Logger.debug ">> is installing a firmware update. I may act weird for a moment",
      channels: [:toast]
    GenServer.cast(Farmbot.Serial.Handler, {:update_fw, file, self})
    receive do
      :done ->
        Logger.debug ">> is done installing a firmware update!", type: :success,
          channels: [:toast]
      {:error, reason} ->
        Logger.error ">> encountered an error installing firmware update!",
          channels: [:toast]
    end
  end

  @doc """
    Shortcut checking updates for the OS
  """
  @spec check_updates(:os) :: update_output
  def check_updates(:os) do
    with {:ok, token} <- Farmbot.Auth.get_token,
    do: check_updates(
          Map.get(token, "unencoded") |> Map.get("os_update_server"),
          Farmbot.BotState.get_os_version,
          ".fw")
  end

  @doc """
    Shortcut checking updates for the Firmware
  """
  @spec check_updates(:fw) :: update_output
  def check_updates(:fw) do
    with {:ok, token} <- Farmbot.Auth.get_token,
    do: check_updates(
          Map.get(token, "unencoded") |> Map.get("fw_update_server"),
          Farmbot.BotState.get_fw_version,
          ".hex")
  end

  @spec check_updates(any) :: {:error, :probably_typo}
  def check_updates(_), do: {:error, :probably_typo}

  @doc """
    Uses Github Release api to check for an update.
    If there is an update on URL, it returns the asset with the given extension
    for said update.
  """
  @spec check_updates(String.t, String.t, String.t) :: update_output
  def check_updates(url, current_version, extension) do
    resp = HTTPotion.get url, [headers: ["User-Agent": "Farmbot"]]
    with {:assets, new_version, assets} <- parse_resp(resp),
         true <- is_updates?(current_version, new_version),
         do: get_dl_url(assets, extension)
  end

  @doc """
    Gets the url with the given extension from the given Github assets
  """
  @spec get_dl_url([any,...] | map, String.t)
  :: {:update, String.t} | {:error, atom}
  def get_dl_url(assets, extension)
  when is_list(assets) do
    Enum.find_value(assets, {:error, :no_assets},
      fn asset ->
        url = get_dl_url(asset)
        if String.contains?(url, extension) do
          {:update, url}
        else
          nil
        end
      end)
  end

  def get_dl_url(asset) when is_map(asset) do
    Map.get(asset, "browser_download_url")
  end

  @doc """
    Checks if two strings are the same lol
  """
  @spec is_updates?(String.t, String.t) :: :no_updates | true
  def is_updates?(current, new) when current == new, do: :no_updates
  def is_updates?(_current, _new), do: true

  @doc """
    Parses the httpotion response.
  """
  @spec parse_resp(HTTPotion.ErrorResponse.t) :: {:error, String.t | atom}
  def parse_resp(%HTTPotion.ErrorResponse{message: error}),
    do: {:error, error}

  @spec parse_resp(HTTPotion.Response.t) :: {:assets, Strint.t, String.t}
  def parse_resp(
    %HTTPotion.Response{
      body: body,
      headers: _headers,
      status_code: 200})
  do
    json = Poison.decode!(body)
    "v"<>new_version = Map.get(json, "tag_name")
    assets = Map.get(json, "assets")
    {:assets, new_version, assets}
  end

  # If we happen to get something weird from httpotion
  @spec parse_resp(any) :: {:error, :bad_resp}
  def parse_resp(_), do: {:error, :bad_resp}
end
