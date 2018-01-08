defmodule Farmbot.HTTP.Response do
  @moduledoc "HTTP Response"
  defstruct [:body, :headers, :status_code]

  @typedoc "HTTP Response"
  @type t :: %__MODULE__{
    body: Farmbot.HTTP.Adapter.body(),
    headers: Farmbot.HTTP.Adapter.headers(),
    status_code: Farmbot.HTTP.Adapter.status_code()
  }
end
