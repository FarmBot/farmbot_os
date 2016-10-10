defmodule SequenceValidator do
  def validate(args, body)
    when is_map(args) and is_list(body) do
    case validate_args(args) do
      {:valid, arg_warnings}
        -> case validate_body(body) do
          {:valid, body_warnings} -> {:valid, arg_warnings ++ body_warnings }
          {:error, reason} -> {:error, reason}
        end
      {:error, reason}
        -> {:error, reason}
    end
  end

  def validate(_args, _body) do
    reason = "bad type of args or body. "
    {:error, reason}
  end

  def validate_args(args) when is_map(args) do
    {:valid, []}
  end

  def validate_body(body) when is_list(body) do
    {:valid, []}
  end
end
