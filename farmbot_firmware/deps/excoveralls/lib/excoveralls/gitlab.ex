defmodule ExCoveralls.Gitlab do
  @moduledoc """
  Handles gitlab-ci integration with coveralls.
  """
  alias ExCoveralls.Poster

  def execute(stats, options) do
    json = generate_json(stats, Enum.into(options, %{}))

    if options[:verbose] do
      IO.puts(json)
    end

    Poster.execute(json)
  end

  def generate_json(stats, options \\ %{})

  def generate_json(stats, options) do
    Jason.encode!(%{
      repo_token: get_repo_token(),
      service_name: "gitlab-ci",
      service_number: get_number(),
      service_job_id: get_job_id(),
      service_pull_request: get_pull_request(),
      source_files: stats,
      git: generate_git_info(),
      parallel: options[:parallel]
    })
  end

  defp generate_git_info do
    %{
      head: %{
        committer_name: get_committer(),
        message: get_message(),
        id: get_sha()
      },
      branch: get_branch()
    }
  end

  def get_pull_request() do
    System.get_env("CI_MERGE_REQUEST_ID") || System.get_env("CI_EXTERNAL_PULL_REQUEST_IID")
  end

  defp get_message do
    System.get_env("CI_COMMIT_TITLE") || "[no commit message]"
  end

  defp get_committer do
    case System.cmd("git", ["log", "-1", "--format=%an"]) do
      {committer, _} -> String.trim(committer)
      _ -> "[no committer name]"
    end
  end

  defp get_sha do
    System.get_env("CI_COMMIT_SHA")
  end

  defp get_branch do
    System.get_env("CI_COMMIT_BRANCH")
  end

  defp get_job_id do
    "#{System.get_env("CI_JOB_ID")}-#{System.get_env("CI_NODE_INDEX")}"
  end

  defp get_number do
    System.get_env("CI_PIPELINE_ID")
  end

  defp get_repo_token do
    System.get_env("COVERALLS_REPO_TOKEN")
  end
end
