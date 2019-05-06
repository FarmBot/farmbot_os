defmodule FarmbotOS.SysCalls.CheckUpdate do
  @moduledoc false

  alias FarmbotOS.Platform.Target.NervesHubClient

  @doc false
  def check_update do
    _ = NervesHubClient.check_update()
    :ok
  end
end
