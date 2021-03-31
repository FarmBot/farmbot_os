defmodule ExCoveralls.Semaphore do
  @moduledoc """
  Handles semaphore-ci integration with coveralls.
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
  def generate_json(stats, options) do
    Jason.encode!(%{
      repo_token: get_repo_token(),
      service_name: "semaphore",
      service_number: get_build_num(),
      service_job_id: get_build_num(),
      service_pull_request: get_pull_request(),
      source_files: stats,
      git: generate_git_info(),
      parallel: options[:parallel]
    })
  end

  defp generate_git_info do
    %{head: %{
       message: get_message!(),
       id: get_sha()
      },
      branch: get_branch()
    }
  end

  defp get_pull_request do
    case Regex.run(~r/(\d+)$/, System.get_env("SEMAPHORE_GIT_PR_NUMBER") || "") do
      [_, id] -> id
      _ -> nil
    end
  end

  defp get_message! do
    case System.cmd("git", ["log", "-1", "--pretty=format:%s"]) do
      {message, _} -> message
      _ -> "[no commit message]"
    end
  end

  defp get_sha do
    System.get_env("SEMAPHORE_GIT_SHA")
  end

  defp get_branch do
    System.get_env("SEMAPHORE_GIT_BRANCH")
  end

  defp get_build_num do
    System.get_env("SEMAPHORE_JOB_ID")
  end

  defp get_repo_token do
    System.get_env("COVERALLS_REPO_TOKEN")
  end
end
