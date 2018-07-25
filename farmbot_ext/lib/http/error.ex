defmodule Farmbot.HTTP.Error do
  @moduledoc "Some Farmbot HTTP Adapter error."

  alias Farmbot.HTTP.{Response}

  defexception [:message, :response]

  @doc false
  def exception(desc) when is_atom(desc) or is_binary(desc) do
    %__MODULE__{message: String.trim(desc)}
  end

  def exception(%Response{status_code: code, body: body} = resp) do
    %__MODULE__{message: "HTTP Request failed (#{code}) body: #{body}", response: resp}
  end
end
