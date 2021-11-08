defmodule FarmbotOS.Celery.AST.Factory do
  @moduledoc """
  Helpers for creating ASTs.
  """

  alias FarmbotOS.Celery.AST

  @doc """
  Create an empty AST WITH ARG SET TO `nil`.

  iex> new()
  %FarmbotOS.Celery.AST{
    args: nil,
    body: [],
    comment: nil,
    kind: nil,
    meta: nil
  }
  """
  def new do
    %AST{body: []}
  end

  @doc """
  Create a new AST to work with. Strings `kind`s are
  converted to symbols.

  iex> new("foo")
  %FarmbotOS.Celery.AST{
    args: %{},
    body: [],
    comment: nil,
    kind: :foo,
    meta: nil
  }
  """
  def new(kind, args \\ %{}, body \\ []) do
    AST.new(kind, Map.new(args), body)
  end

  def rpc_request(%AST{} = ast, label) when is_binary(label) do
    %AST{ast | kind: :rpc_request, args: %{label: label}, body: []}
  end

  def read_pin(%AST{} = ast, pin_number, pin_mode) do
    ast
    |> add_body_node(
      new(:read_pin, %{pin_number: pin_number, pin_mode: pin_mode})
    )
  end

  @doc """
  iex> (new() |> rpc_request("x") |> set_pin_io_mode(13, 1)).body
  [%FarmbotOS.Celery.AST{
    kind: :set_pin_io_mode,
    args: %{ pin_io_mode: 1, pin_number: 13 },
    body: [],
    comment: nil,
    meta: nil
  }]
  """
  def set_pin_io_mode(%AST{} = ast, pin_number, pin_io_mode) do
    args = %{pin_number: pin_number, pin_io_mode: pin_io_mode}
    ast |> add_body_node(new(:set_pin_io_mode, args))
  end

  @doc """
  iex> (new() |> rpc_request("x") |> emergency_lock()).body
  [%FarmbotOS.Celery.AST{
    body: [],
    comment: nil,
    meta: nil,
    args: %{},
    kind: :emergency_lock
  }]
  """
  def emergency_lock(%AST{} = ast) do
    ast |> add_body_node(new(:emergency_lock))
  end

  @doc """
  iex> (new() |> rpc_request("x") |> emergency_unlock()).body
  [%FarmbotOS.Celery.AST{
    body: [],
    comment: nil,
    meta: nil,
    args: %{},
    kind: :emergency_unlock
  }]
  """
  def emergency_unlock(%AST{} = ast) do
    ast |> add_body_node(new(:emergency_unlock))
  end

  @doc """
  iex> (new() |> rpc_request("x") |> read_status()).body
  [%FarmbotOS.Celery.AST{
    body: [],
    comment: nil,
    meta: nil,
    args: %{},
    kind: :read_status
  }]
  """
  def read_status(%AST{} = ast) do
    ast |> add_body_node(new(:read_status))
  end

  @doc """
  iex> (new() |> rpc_request("x") |> power_off()).body
  [%FarmbotOS.Celery.AST{
    body: [],
    comment: nil,
    meta: nil,
    args: %{},
    kind: :power_off
  }]
  """
  def power_off(%AST{} = ast) do
    ast |> add_body_node(new(:power_off))
  end

  @doc """
  iex> (new() |> rpc_request("x") |> reboot()).body
  [%FarmbotOS.Celery.AST{
    body: [],
    comment: nil,
    meta: nil,
    args: %{},
    kind: :reboot
  }]
  """
  def reboot(%AST{} = ast) do
    ast |> add_body_node(new(:reboot))
  end

  @doc """
  iex> (new() |> rpc_request("x") |> sync()).body
  [%FarmbotOS.Celery.AST{
    body: [],
    comment: nil,
    meta: nil,
    args: %{},
    kind: :sync
  }]
  """
  def sync(%AST{} = ast) do
    ast |> add_body_node(new(:sync))
  end

  @doc """
  iex> (new() |> rpc_request("x") |> take_photo()).body
  [%FarmbotOS.Celery.AST{
    body: [],
    comment: nil,
    meta: nil,
    args: %{},
    kind: :take_photo
  }]
  """
  def take_photo(%AST{} = ast) do
    ast |> add_body_node(new(:take_photo))
  end

  @doc """
  iex> (new() |> rpc_request("x") |> flash_firmware("arduino")).body
  [%FarmbotOS.Celery.AST{
      kind: :flash_firmware,
      comment: nil,
      meta: nil,
      args: %{package: "arduino"},
      body: [],
  }]
  """
  def flash_firmware(%AST{} = ast, package) when is_binary(package) do
    ast |> add_body_node(new(:flash_firmware, %{package: package}))
  end

  @doc """
  iex> (new() |> rpc_request("x") |> factory_reset("arduino")).body
  [%FarmbotOS.Celery.AST{
      kind: :factory_reset,
      comment: nil,
      meta: nil,
      args: %{package: "arduino"},
      body: [],
  }]
  """
  def factory_reset(%AST{} = ast, package) do
    ast |> add_body_node(new(:factory_reset, %{package: package}))
  end

  def add_body_node(%AST{body: body} = ast, %AST{} = body_node) do
    %{ast | body: body ++ [body_node]}
  end
end
