defmodule ExCoveralls.Circle do
  @moduledoc """
  Handles circle-ci integration with coveralls.
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
      service_name: "circle-ci",
      service_number: get_number(),
      service_job_id: get_job_id(),
      service_pull_request: get_pull_request(),
      source_files: stats,
      git: generate_git_info(),
      parallel: options[:parallel]
    })
  end

  defp generate_git_info do
    %{head: %{
       committer_name: get_committer(),
       message: get_message!(),
       id: get_sha()
      },
      branch: get_branch()
    }
  end

  defp get_pull_request do
    case Regex.run(~r/(\d+)$/, System.get_env("CI_PULL_REQUEST") || "") do
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

  defp get_committer do
    System.get_env("CIRCLE_USERNAME")
  end

  defp get_sha do
    System.get_env("CIRCLE_SHA1")
  end

  defp get_branch do
    System.get_env("CIRCLE_BRANCH")
  end

  defp get_job_id do
    # When using workflows, each job has a separate `CIRCLE_BUILD_NUM`, so this needs to be used as the Job ID and not
    # the Job Number. If the job is configured with `parallelism` greater than one, then the `CIRCLE_NODE_INDEX` is
    # used to differentiate between separate containers running the same job.
    "#{System.get_env("CIRCLE_BUILD_NUM")}-#{System.get_env("CIRCLE_NODE_INDEX")}"
  end

  defp get_number do
    # `CIRCLE_WORKFLOW_WORKSPACE_ID` is the same when "Rerun failed job" is done while `CIRCLE_WORKFLOW_ID` changes, so
    # use `CIRCLE_WORKFLOW_WORKSPACE_ID` so that the results from the original and rerun are combined
    System.get_env("CIRCLE_WORKFLOW_WORKSPACE_ID") || System.get_env("CIRCLE_BUILD_NUM")
  end

  defp get_repo_token do
    System.get_env("COVERALLS_REPO_TOKEN")
  end
end
