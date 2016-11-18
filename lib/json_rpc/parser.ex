defmodule RPC.Parser do
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
