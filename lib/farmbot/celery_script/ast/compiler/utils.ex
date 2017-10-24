defmodule Farmbot.CeleryScript.AST.Compiler.Utils do
  alias Farmbot.CeleryScript.VirtualMachine.InstructionSet
  def compiler_debug_log(kind, msg) do
    msg =
      "#{format_kind(kind)}" <>
        "#{Farmbot.DebugLog.color(:LIGHT_GREEN)}[ " <> msg <> " ]#{Farmbot.DebugLog.color(:NC)}"

    compiler_debug_log(msg)
  end

  def compiler_debug_log_begin_step(ast, step) do
    compiler_debug_log(
      "#{Farmbot.DebugLog.color(:YELLOW)}[ #{inspect ast} ] " <> # "#{ast.__meta__.encoded} " <>
      "#{Farmbot.DebugLog.color(:LIGHT_GREEN)}begin step: #{Farmbot.DebugLog.color(:YELLOW)}[ #{step} ]#{
        Farmbot.DebugLog.color(:NC)
      }"
    )
  end

  def compiler_debug_log_complete_step(ast, step) do
    compiler_debug_log(
      "#{Farmbot.DebugLog.color(:YELLOW)}[ #{inspect ast} ] " <>#  "#{ast.__meta__.encoded} " <>
      "#{Farmbot.DebugLog.color(:LIGHT_GREEN)}complete step: #{Farmbot.DebugLog.color(:YELLOW)}[ #{step} ]#{
        Farmbot.DebugLog.color(:NC)
      }"
    )
  end

  def compiler_debug_log(msg) do
    IO.puts(msg)
  end

  kinds = Map.keys(struct(InstructionSet)) -- [:__struct__]

  max_chars =
    Enum.reduce(kinds, 0, fn kind, acc ->
      num_chars = to_charlist(kind) |> Enum.count()

      if num_chars > acc do
        num_chars
      else
        acc
      end
    end)

  for kind <- kinds do
    num_chars = to_charlist(kind) |> Enum.count()
    pad = max_chars - num_chars
    # "#{String.duplicate(" ", pad)} - " <>
    res =
      "#{Farmbot.DebugLog.color(:LIGHT_CYAN)}" <>
        "[ " <>
        "#{Farmbot.DebugLog.color(:CYAN)}#{kind}" <>
        "#{String.duplicate(" ", pad)}" <>
        "#{Farmbot.DebugLog.color(:LIGHT_CYAN)} ]" <> "#{Farmbot.DebugLog.color(:NC)} - "

    def format_kind(unquote(kind |> to_string())), do: unquote(res)
  end
end
