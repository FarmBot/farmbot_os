defmodule Farmbot.Test.Helpers.Context do
  alias Farmbot.Context

  def replace_http(%Context{} = context) do
    {:ok, pid} = Farmbot.Test.Helpers.HTTP.start_link
    %{context | http: pid}
  end
end
