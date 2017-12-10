defmodule Farmbot.Host.UpdateHandler do
  @moduledoc false

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

  def setup(_env) do
    :ok
  end
end
