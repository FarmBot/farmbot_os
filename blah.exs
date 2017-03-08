defmodule F do
  require Logger
  @path "/tmp/logs.txt"

  def blah(count) when count > 10000 do
    print()
  end

  def blah(count \\ 0) do
    Logger.debug random_number()
    blah(count + 1)
  end

  def print do
    f = case File.stat(@path) do
      {:ok, f} -> f
      _ ->
        seed()
        print()
    end
    if f.size > 52000, do: Logger.warn "File is too big!"
    blah = File.read! @path
    [rhead | _rest] = String.split(blah, "\r\n")
    Logger.debug "File size is: #{f.size}"
    Logger.debug "First line is: #{rhead}"
  end

  def random_number do
    :rand.uniform(:os.system_time)
  end

  def seed do
    for i <- 0..50, do: Logger.debug "Seeding: #{i}"
  end
end
