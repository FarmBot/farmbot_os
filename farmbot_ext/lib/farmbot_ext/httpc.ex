defmodule FarmbotExt.HTTPC do
  @moduledoc """
  A very thin wrapper around FarmbotExt.HTTPC.request to facilitate
  mocking. Do not add functionality to the module.
  """
  def request(method, params, opts1, opts2) do
    :httpc.request(method, params, opts1, opts2)
  end
end
