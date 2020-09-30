defmodule FarmbotCeleryScript.SpecialValue do
  alias FarmbotCeleryScript.SysCalls
  require Logger

  def safe_height(), do: fetch_float(:safe_height)
  def soil_height(), do: fetch_float(:soil_height)

  def fetch_float(key, default \\ 0.0) do
    with {:ok, conf} <- SysCalls.fbos_config(),
         {:ok, value} <- Map.fetch(conf, key) do
      value || default
    else
      e ->
        msg =
          "Error fetching #{key}. Using default of #{default}. (#{inspect(e)})"

        SysCalls.log(msg)
        default
    end
  end
end
