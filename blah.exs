defmodule Mix do
  def env, do: :dev
  defmodule Project do
    def config do
      [version: "1.2.3", target: "rpi3", commit: "abcdef"]
    end
  end
end
