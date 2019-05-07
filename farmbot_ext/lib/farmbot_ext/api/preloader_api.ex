defmodule FarmbotExt.API.PreloaderApi do
  @moduledoc """
  Behavior implementing the resource preloader's API.
  """

  @callback preload_all() :: :ok
end
