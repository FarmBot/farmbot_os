defmodule Request do
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
end

defmodule Notification do
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
end

defmodule Response do
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
end
