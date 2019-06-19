defmodule FarmbotOS.Configurator.NetworkLayer do
  @callback list_interfaces() :: [String.t()]
  @callback scan(String.t()) :: [map()]
end
