defmodule Farmbot.HTTP.Helpers do
  @moduledoc false

  @doc "Helper for checking status codes"
  defmacro is_2xx(number) do
    quote do
      unquote(number) > 199 and unquote(number) < 300
    end
  end

  # Defines a function to fetch and decode an api resource.
  @doc "Helper to define fetch and decode resource function in Farmbot.HTTP"
  defmacro fadr(plural, kind) do
    quote do
      def unquote(plural)(),
        do: fetch_and_decode("/api/#{unquote(plural)}.json", unquote(kind))
    end
  end
end
