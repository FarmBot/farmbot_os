defmodule ExCoveralls.Drone do
  @moduledoc """
  Handles drone-ci integration with coveralls.
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
      service_name: "drone",
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
       committer_name: get_committer(),
       message: get_message(),
       id: get_sha()
      },
      branch: get_branch()
    }
  end

  defp get_pull_request do
    System.get_env("DRONE_PULL_REQUEST")
  end

  defp get_message do
    System.get_env("DRONE_COMMIT_MESSAGE")
  end

  defp get_committer do
    System.get_env("DRONE_COMMIT_AUTHOR")
  end

  defp get_sha do
    System.get_env("DRONE_COMMIT_SHA")
  end

  defp get_branch do
    System.get_env("DRONE_BRANCH")
  end

  defp get_build_num do
    System.get_env("DRONE_BUILD_NUMBER")
  end

  defp get_repo_token do
    System.get_env("COVERALLS_REPO_TOKEN")
  end
end
