defmodule FarmbotCeleryScript.AST.Factory do
  @moduledoc """
  Helpers for creating ASTs.
  """

  alias FarmbotCeleryScript.AST

  def new do
    %AST{body: []}
  end

  def new(kind, args \\ %{}, body \\ []) do
    AST.new(kind, Map.new(args), body)
  end

  def rpc_request(%AST{} = ast, label) when is_binary(label) do
    %AST{ast | kind: :rpc_request, args: %{label: label}, body: []}
  end

  def read_pin(%AST{} = ast, pin_number, pin_mode) do
    ast
    |> add_body_node(new(:read_pin, %{pin_number: pin_number, pin_mode: pin_mode}))
  end

  def dump_info(%AST{} = ast) do
    ast
    |> add_body_node(new(:dump_info))
  end

  def emergency_lock(%AST{} = ast) do
    ast
    |> add_body_node(new(:emergency_lock))
  end

  def emergency_unlock(%AST{} = ast) do
    ast
    |> add_body_node(new(:emergency_unlock))
  end

  def read_status(%AST{} = ast) do
    ast
    |> add_body_node(new(:read_status))
  end

  def power_off(%AST{} = ast) do
    ast
    |> add_body_node(new(:power_off))
  end

  def reboot(%AST{} = ast) do
    ast
    |> add_body_node(new(:reboot))
  end

  def sync(%AST{} = ast) do
    ast
    |> add_body_node(new(:sync))
  end

  def take_photo(%AST{} = ast) do
    ast
    |> add_body_node(new(:take_photo))
  end

  def add_body_node(%AST{body: body} = ast, %AST{} = body_node) do
    %{ast | body: body ++ [body_node]}
  end
end
