defmodule Mimic.Module do
  alias Mimic.{Cover, Server}
  @moduledoc false

  def original(module), do: "#{module}.Mimic.Original.Module" |> String.to_atom()

  def clear!(module) do
    :code.purge(module)
    :code.delete(module)
    :code.purge(original(module))
    :code.delete(original(module))
    :ok
  end

  def replace!(module) do
    backup_module = original(module)

    case :cover.is_compiled(module) do
      {:file, beam_file} ->
        coverdata_path = Cover.export_coverdata!(module)
        Server.store_beam_and_coverdata(module, beam_file, coverdata_path)

      false ->
        :ok
    end

    rename_module(module, backup_module)
    Code.compiler_options(ignore_module_conflict: true)
    create_mock(module)
    Code.compiler_options(ignore_module_conflict: false)

    :ok
  end

  defp rename_module(module, new_module) do
    beam_code = beam_code(module)

    {:ok, {_, [{:abstract_code, {:raw_abstract_v1, forms}}]}} =
      :beam_lib.chunks(beam_code, [:abstract_code])

    forms = rename_attribute(forms, new_module)

    case :compile.forms(forms, compiler_options(module)) do
      {:ok, module_name, binary} ->
        load_binary(module_name, binary)
        binary

      {:ok, module_name, binary, _warnings} ->
        load_binary(module_name, binary)
        Binary
    end
  end

  defp beam_code(module) do
    case :code.get_object_code(module) do
      {_, binary, _filename} -> binary
      _error -> throw({:object_code_not_found, module})
    end
  end

  defp compiler_options(module) do
    options =
      module.module_info(:compile)
      |> Keyword.get(:options)
      |> Enum.filter(&(&1 != :from_core))

    [:return_errors | [:debug_info | options]]
  end

  defp load_binary(module, binary) do
    case :code.load_binary(module, '', binary) do
      {:module, ^module} -> :ok
      {:error, reason} -> exit({:error_loading_module, module, reason})
    end

    apply(:cover, :compile_beams, [[{module, binary}]])
  end

  defp rename_attribute([{:attribute, line, :module, {_, vars}} | t], new_name) do
    [{:attribute, line, :module, {new_name, vars}} | t]
  end

  defp rename_attribute([{:attribute, line, :module, _} | t], new_name) do
    [{:attribute, line, :module, new_name} | t]
  end

  defp rename_attribute([h | t], new_name), do: [h | rename_attribute(t, new_name)]

  defp create_mock(module) do
    mimic_info = module_mimic_info()
    mimic_behaviours = generate_mimic_behaviours(module)
    mimic_functions = generate_mimic_functions(module)
    quoted = [mimic_info | [mimic_behaviours ++ mimic_functions]]
    Module.create(module, quoted, Macro.Env.location(__ENV__))
    module
  end

  defp module_mimic_info do
    quote do: def(__mimic_info__, do: :ok)
  end

  defp generate_mimic_functions(module) do
    internal_functions = [__info__: 1, module_info: 0, module_info: 1]

    for {fn_name, arity} <- module.module_info(:exports),
        {fn_name, arity} not in internal_functions do
      args =
        0..arity
        |> Enum.to_list()
        |> tl()
        |> Enum.map(&Macro.var(String.to_atom("arg_#{&1}"), Elixir))

      quote do
        def unquote(fn_name)(unquote_splicing(args)) do
          Server.apply(__MODULE__, unquote(fn_name), unquote(args))
        end
      end
    end
  end

  defp generate_mimic_behaviours(module) do
    module.module_info(:attributes)
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
    |> Enum.map(fn behaviour ->
      quote do
        @behaviour unquote(behaviour)
      end
    end)
  end
end
