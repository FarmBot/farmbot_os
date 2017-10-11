defmodule Farmbot.HTTP.Helpers do
  @moduledoc """
    Helpful stuff.
  """

  @doc """
    Helper for checking status codes
  """
  defmacro is_2xx(number) do
    quote do
      unquote(number) > 199 and unquote(number) < 300
    end
  end
end
