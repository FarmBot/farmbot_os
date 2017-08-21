defmodule ExSyslogger.FarmbotFormatterTest do
  @moduledoc "Tests the prod syslogger."
  use ExUnit.Case
  alias ExSyslogger.FarmbotFormatter, as: Formatter
  @format "$date $time [$level] $levelpad $metadata $message\n"

  setup do
    format = Formatter.compile(@format)
    timestamp = {{1990, 7, 22}, {10, 20, 0, 0}}
    [format: format, timestamp: timestamp]
  end

  test "formats a message that can be turned to a string", %{format: format, timestamp: timestamp} do
    assert Formatter.format(format, :error, 'hello world', timestamp, [], []) == "1990-07-22 10:20:00.000 [error]   hello world\n"
  end

  test "formats a message with no native `to_string` implementation", %{format: format, timestamp: timestamp} do
    assert Formatter.format(format, :info, %{hello: :world}, timestamp, [], []) == "1990-07-22 10:20:00.000 [info]    %{hello: :world}\n"
  end
end
