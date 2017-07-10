defmodule Farmbot.HTTP.Response do
  @moduledoc "HTTP Response"
  defstruct [:body, :headers, :status_code]

  @typedoc "HTTP Response"
  @type t :: %__MODULE__{
    body:        Farmbot.Behaviour.HTTP.body,
    headers:     Farmbot.Behaviour.HTTP.headers,
    status_code: Farmbot.Behaviour.HTTP.status_code
  }

end
