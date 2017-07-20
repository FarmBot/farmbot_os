defmodule Farmbot.HTTP.Error do
  @moduledoc "Some Farmbot HTTP Adapter error."

  alias Farmbot.HTTP.{Response}

  defexception [:message, :response]

  def exception(desc) when is_atom(desc) or is_binary(desc) do
    %__MODULE__{message: String.trim("#{inspect desc}")}
  end

  def exception(%Response{status_code: code, body: body} = resp) do
    %__MODULE__{message: "HTTP Request failed (#{code}) body: #{body}", response: resp}
  end

  def exception(other) do
    %__MODULE__{message: "Unknown error: #{inspect other}"}
  end

  def message(%{message: message}), do: message
end
