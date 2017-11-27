defmodule Farmbot.BotState.Utils do
  @moduledoc "Utility functions for handling bot_state data"

  def should_log?(module, verbosity)
  def should_log?(nil, verbosity) when verbosity < 3, do: true
  def should_log?(nil, _), do: false

  def should_log?(module, verbosity) when verbosity < 3 do
    List.first(Module.split(module))  == "Farmbot"
  end

  def should_log?(_, _), do: false
end
