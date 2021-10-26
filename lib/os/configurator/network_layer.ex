defmodule FarmbotOS.Configurator.NetworkLayer do
  @moduledoc """
  intermediate layer for stubbing Network interactions
  """

  @doc "list network interfaces that can be configured"
  @callback list_interfaces() :: [String.t()]

  @doc "scan for wifi networks"
  @callback scan(String.t()) :: [map()]
end
