defmodule Farmbot.HTTP.Response do
  @moduledoc """
    a valid http response.
  """
  defstruct [:status_code, :body, :headers]

  @type t :: %__MODULE__{
    status_code: pos_integer,
    body: binary,
    headers: [{char_list, char_list}]
  }
end
