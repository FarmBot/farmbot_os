# Module doc Common for both.
mdoc = """
Provides a `debug_log/1` function.
"""
use_logger? =
  case System.get_env("DEBUG_LOGGER") do
    "false" -> false
    nil -> false
    _ -> true
  end
# Check fof if logger is enabled.
if use_logger? do

  # We do enable debug logger.
  defmodule Farmbot.DebugLog do
    @moduledoc mdoc

    defmacro __using__(enable: false) do
      quote do
        def debug_log(_str), do: :ok
      end
    end

    defmacro __using__(_opts) do
      quote do
        def debug_log(str), do: IO.puts "[#{__MODULE__}] #{str}"
      end # quote
    end # defmacro
  end # defmodule
  
else

  # We dont enable Debug logger. Stub everything.
  defmodule Farmbot.DebugLog do
    @moduledoc mdoc

    defmacro __using__(_opts) do
      quote do
        # warning = """
        # Disabling DebugLogger: #{__MODULE__}
        # If you want to debug #{__MODULE__}, export: DEBUG_LOGGER=true
        # """
        # IO.warn warning, []
        def debug_log(_str), do: :ok
      end # quote

    end # defmacro

  end # defmodule

end
