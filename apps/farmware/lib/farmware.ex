defmodule Farmware do
  @moduledoc """
    Interface with Farmware.

    IDEA(Connor):
     Farmware will just be specially constructed zipfile with a json manifest?
     we keep the scripts in organized folders under `FS.path() <> "/farmware"`
     so we would have something along the lines of:

       [/state/farmware]
       |-- [plant_detection]
       |    |- PlantDetection.py
       |    |- farmware.json
       |
       |-- [other_farmware]
            |- farmware.json
            |- do_some_cool_thing.rb

    * this means we will have to deal with maintaining disk usage on the state part
    * we will have to do some sort of validation (maybe just parse manifest file?)

    This module will do an HTTP get to a url with a manifest.json file maybe?
    it parses that manifest.json file, and downloads a zip file containing the
    stuff required for the script to work?

    ```json
      {
        "package": "plant_detection",
        "language": "python",
        "author": "farmbot.io",
        "description": "detect plants from images?",
        "version": "0.0.1",
        "min_os_version_major": "3",
        "url": "url to this file?",
        "zip": "url to zip file?",
        "command": "pythmon PlantDetectionx.py"
      }
    ```

    then we can access the "Farmware" by pushing it onto the tracker stack?



  """
  alias Farmbot.System.FS
  require Logger

  @doc """
    Gets a Farmware zip from a given url.
  """
  def get(url) do
    Logger.debug ">> getting some Farmware."
    tmp_file = "/tmp/farmware.zip"

    Downloader.run(url, tmp_file)

    FS.transaction fn() ->
      unzip_file(tmp_file, FS.path() <> "/farmware/")
    end

    File.rm_rf(tmp_file)
  end

  defp unzip_file(zip_file, path) when is_bitstring(zip_file) do
    File.cd path
    :zip.unzip(String.to_charlist(zip_file))
  end
end
