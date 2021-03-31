defmodule ExCoveralls do
  @moduledoc """
  Provides the entry point for coverage calculation and output.
  This module method is called by Mix.Tasks.Test
  """
  alias ExCoveralls.Stats
  alias ExCoveralls.Cover
  alias ExCoveralls.ConfServer
  alias ExCoveralls.StatServer
  alias ExCoveralls.Travis
  alias ExCoveralls.Github
  alias ExCoveralls.Gitlab
  alias ExCoveralls.Circle
  alias ExCoveralls.Semaphore
  alias ExCoveralls.Drone
  alias ExCoveralls.Local
  alias ExCoveralls.Html
  alias ExCoveralls.Json
  alias ExCoveralls.Post
  alias ExCoveralls.Xml

  @type_travis      "travis"
  @type_github      "github"
  @type_gitlab      "gitlab"
  @type_circle      "circle"
  @type_semaphore   "semaphore"
  @type_drone       "drone"
  @type_local       "local"
  @type_html        "html"
  @type_json        "json"
  @type_post        "post"
  @type_xml         "xml"

  @doc """
  This method will be called from mix to trigger coverage analysis.
  """
  def start(compile_path, _opts) do
    Cover.compile(compile_path)
    fn() ->
      execute(ConfServer.get, compile_path)
    end
  end

  def execute(options, compile_path) do
    stats = Cover.modules() |> Stats.report() |> Enum.map(&Enum.into(&1, %{}))

    if options[:umbrella] do
      store_stats(stats, options, compile_path)
    else
      analyze(stats, options[:type] || "local", options)
    end
  end

  defp store_stats(stats, options, compile_path) do
    {sub_app_name, _sub_app_path} =
      ExCoveralls.SubApps.find(options[:sub_apps], compile_path)
    stats = Stats.append_sub_app_name(stats, sub_app_name, options[:apps_path])
    Enum.each(stats, fn(stat) -> StatServer.add(stat) end)
  end

  @doc """
  Logic for posting
  """
  def analyze(stats, type, options)

  def analyze(stats, @type_travis, options) do
    Travis.execute(stats, options)
  end

  def analyze(stats, @type_github, options) do
    Github.execute(stats, options)
  end

  def analyze(stats, @type_gitlab, options) do
    Gitlab.execute(stats, options)
  end

  def analyze(stats, @type_circle, options) do
    Circle.execute(stats, options)
  end

  def analyze(stats, @type_semaphore, options) do
    Semaphore.execute(stats, options)
  end

  def analyze(stats, @type_drone, options) do
    Drone.execute(stats, options)
  end

  def analyze(stats, @type_local, options) do
    Local.execute(stats, options)
  end

  def analyze(stats, @type_html, options) do
    Html.execute(stats, options)
  end

  def analyze(stats, @type_json, options) do
    Json.execute(stats, options)
  end

  def analyze(stats, @type_xml, options) do
    Xml.execute(stats, options)
  end

  def analyze(stats, @type_post, options) do
    Post.execute(stats, options)
  end

  def analyze(_stats, type, _options) do
    raise "Undefined type (#{type}) is specified for ExCoveralls"
  end
end
