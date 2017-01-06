defmodule FileSystem.Utils do
  @moduledoc """
    A behaviour for filesystem access modules.
  """
  @type ret_val :: :ok | {:error, atom}
  @callback mount_read_only :: ret_val
  @callback mount_read_write :: ret_val
  @callback fs_init :: ret_val
  @callback factory_reset :: ret_val
end

defmodule Module.concat([FileSystem, Utils, :dev, "development"]) do
  @moduledoc """
    Spoofs Filesystem access in development mode.
  """
  @behaviour FileSystem.Utils
  @doc false
  def mount_read_only, do: :ok
  @doc false
  def mount_read_write, do: :ok
  @doc false
  def fs_init, do: :ok
  def factory_reset, do: :ok
end

defmodule Module.concat([FileSystem, Utils, :test, "development"]) do
  @moduledoc """
    Spoofs Filesystem access in development mode.
  """
  @behaviour FileSystem.Utils
  @doc false
  def mount_read_only, do: :ok
  @doc false
  def mount_read_write, do: :ok
  @doc false
  def fs_init, do: :ok
  def factory_reset, do: :ok
end

defmodule Module.concat([FileSystem, Utils, :prod, "qemu"]) do
  @moduledoc """
    FileSystem access functions.
  """
  @behaviour FileSystem.Utils

  @doc false
  def mount_read_only, do: :ok
  @doc false
  def mount_read_write, do: :ok

  @doc false
  def fs_init, do: :ok

  @doc false
  def factory_reset, do: :ok
end
