defmodule Farmbot.DebugLog do
  @moduledoc false

  @doc false
  def color(:NC),           do: "\e[0m"
  def color(:WHITE),        do: "\e[1;37m"
  def color(:BLACK),        do: "\e[0;30m"
  def color(:BLUE),         do: "\e[0;34m"
  def color(:LIGHT_BLUE),   do: "\e[1;34m"
  def color(:GREEN),        do: "\e[0;32m"
  def color(:LIGHT_GREEN),  do: "\e[1;32m"
  def color(:CYAN),         do: "\e[0;36m"
  def color(:LIGHT_CYAN),   do: "\e[1;36m"
  def color(:RED),          do: "\e[0;31m"
  def color(:LIGHT_RED),    do: "\e[1;31m"
  def color(:PURPLE),       do: "\e[0;35m"
  def color(:LIGHT_PURPLE), do: "\e[1;35m"
  def color(:BROWN),        do: "\e[0;33m"
  def color(:YELLOW),       do: "\e[1;33m"
  def color(:GRAY),         do: "\e[0;30m"
  def color(:LIGHT_GRAY),   do: "\e[0;37m"
  def color(:RANDOM) do
    Enum.random([:NC, :WHITE, :BLACK, :BLUE, :LIGHT_BLUE, :GREEN, :LIGHT_GREEN, :CYAN, :LIGHT_CYAN, :RED, :LIGHT_RED, :PURPLE, :LIGHT_PURPLE, :BROWN, :YELLOW, :GRAY, :LIGHT_GRAY])
    |> color()
  end
end
