defmodule Farmbot.Context.Consumer do
  @moduledoc """
    Behaviour for consuming a context object.
  """
  alias Farmbot.Context

  @doc """
    A list of requirements required by a `Consumer`
  """
  @callback requirements :: [Context.modules]
end
