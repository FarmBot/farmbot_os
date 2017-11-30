defmodule FarmbotTestSupport.TestUpdateHandler do
  @moduledoc "Handles prep and post OTA update."

  @behaviour Farmbot.System.UpdateHandler
  use Farmbot.Logger

  # Update Handler callbacks

  def apply_firmware(_file_path) do
    :ok
  end

  def before_update do
    :ok
  end

  def post_update do
    :ok
  end
end
