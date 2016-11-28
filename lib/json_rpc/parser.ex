defmodule RPC.Parser do
  @moduledoc """
    Parses JSON RPC.
  """
  alias RPC.Spec.Notification, as: Notification
  alias RPC.Spec.Request, as: Request
  alias RPC.Spec.Response, as: Response
  @spec parse(map) :: Notification.t | Request.t | Response.t | :not_valid
  # Notification
  def parse(%{"id" => nil, "method" => method, "params" => params}) do
    %Notification{id: nil, method: method, params: params}
  end

  # Request
  def parse(%{"id" => id, "method" => method, "params" => params}) do
    %Request{id: id, method: method, params: params}
  end

  # Response
  def parse(%{"result" => result, "error" => error, "id" => id}) do
    %Response{result: result, error: error, id: id}
  end

  def parse(_blah) do
    :not_valid
  end
end
