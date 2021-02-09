defmodule FarmbotExt.HTTP do
  @moduledoc """
  A very thin wrapper around :httpc and :hackney to facilitate
  mocking. Do not add functionality to the module.
  """
  def request(method, params, opts1, opts2) do
    :httpc.request(method, params, opts1, opts2)
  end

  def hackney(), do: :hackney
end
