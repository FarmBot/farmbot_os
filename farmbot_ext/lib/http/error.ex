defmodule Farmbot.HTTP.Error do
  @moduledoc "Some Farmbot HTTP Adapter error."

  alias Farmbot.HTTP.{Response, Error}

  defexception [:message, :response]

  @doc false
  def exception(desc) when is_atom(desc) or is_binary(desc) do
    %Error{message: String.trim(desc)}
  end

  def exception(%Response{status_code: code, body: body} = resp) do
    case Farmbot.JSON.decode(body) do
      {:ok, %{"error" => reason}} ->
        %Error{message: "HTTP Request failed (#{code}) #{reason}", response: resp}
      _ ->
        %Error{message: "HTTP Request failed (#{code})", response: resp}
    end
  end
end
