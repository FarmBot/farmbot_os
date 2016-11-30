defmodule RPC.Spec do
  # TODO: maybe document rpc spec here or in the following modules?
  @moduledoc false
  defmodule Request do
    @moduledoc false
    @type t :: %__MODULE__{
      method: String.t,
      params: [map,...],
      id: String.t
    }
    defstruct [
      method: nil,
      params: nil,
      id: nil
    ]
    def create(%{
      "method" => method,
      "params" => params,
      "id" => id
      })
    do
      %__MODULE__{
        method: method,
        params: params,
        id: id
      }
    end

    def create(_), do: :error
  end

  defmodule Notification do
    @moduledoc false
    @type t :: %__MODULE__{
      method: String.t,
      params: [map,...],
      id: nil
    }
    defstruct [
      method: nil,
      params: nil,
      id: nil
    ]
    def create(%{
      "method" => method,
      "params" => params,
      "id" => nil
      })
    do
      %__MODULE__{
        method: method,
        params: params,
        id: nil
      }
    end

    def create(_), do: :error
  end

  defmodule Response do
    @moduledoc false
    @type t :: %__MODULE__{
      result: any,
      error: String.t | nil,
      id: String.t
    }
    defstruct [
      result: nil,
      error: nil,
      id: nil
    ]
    def create(%{
      "result" => result,
      "error" => error,
      "id" => id
      })
    do
      %__MODULE__{
        result: result,
        error: error,
        id: id
      }
    end
    def create(_), do: :error
  end
end
