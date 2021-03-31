defmodule ExCoveralls.Travis do
  @moduledoc """
  Handles travis-ci integration with coveralls.
  """
  alias ExCoveralls.Poster

  def execute(stats, options) do
    json = generate_json(stats, Enum.into(options, %{}))
    if options[:verbose] do
      IO.puts json
    end
    Poster.execute(json)
  end

  def generate_json(stats, options \\ %{})
  def generate_json(stats, %{ pro: true }) do
    Jason.encode!(%{
      service_job_id: get_job_id(),
      service_name: "travis-pro",
      repo_token: get_repo_token(),
      source_files: stats,
      git: generate_git_info()
    })
  end
  def generate_json(stats, _options) do
    Jason.encode!(%{
      service_job_id: get_job_id(),
      service_name: "travis-ci",
      source_files: stats,
      git: generate_git_info()
    })
  end

  defp get_job_id do
    System.get_env("TRAVIS_JOB_ID")
  end

  defp get_repo_token do
    System.get_env("COVERALLS_REPO_TOKEN")
  end

  defp get_branch do
    System.get_env("TRAVIS_BRANCH")
  end

  defp generate_git_info do
    %{branch: get_branch()}
  end
end
