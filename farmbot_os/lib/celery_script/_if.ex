defmodule Farmbot.OS.IOLayer.If do
  @moduledoc false

  alias Farmbot.{Asset, Firmware}

  def execute(%{lhs: lhs, op: op, rhs: rhs}, _body) do
    case eval_lhs(lhs) do
      {:ok, left} ->
        left
        |> eval_if(op, rhs)

      {:error, _} = err ->
        err
    end
  end

  def eval_lhs(axis) when axis in ["x", "y", "z"] do
    case Firmware.request({:position_read, []}) do
      {:ok, {_, {:report_position, pos}}} ->
        Keyword.fetch!(pos, String.to_existing_atom(axis))

      _ ->
        {:error, "Firmware Error reading position"}
    end
  end

  def eval_lhs(%{kind: :named_pin} = named_pin) do
    id = named_pin.args.pin_id
    type = named_pin.args.pin_type

    case fetch_resource(type, id) do
      {:ok, number} -> eval_lhs("pin#{number}")
      {:error, reason} -> {:error, reason}
    end
  end

  def eval_lhs("pin" <> p) do
    p = String.to_integer(p)

    case Firmware.request({:pin_read, [p: p]}) do
      {:ok, {_, {:report_pin_value, [p: ^p, v: v]}}} -> {:ok, v}
      _ -> {:error, "Firmware error reading pin: #{p}"}
    end
  end

  defp fetch_resource("Peripheral", id) do
    case Asset.get_peripheral(id: id) do
      nil -> {:error, "could not find Peripheral #{id}"}
      %{pin: p} -> {:ok, p}
    end
  end

  defp fetch_resource(unknown_type, _) do
    {:error, "Unknown resource type: #{unknown_type}"}
  end

  defp eval_if(nil, "is_undefined", _), do: {:ok, true}
  defp eval_if(_, "is_undefined", _), do: {:ok, false}

  defp eval_if(nil, _, _),
    do: {:error, "Could not eval IF because left hand side of if statement is undefined."}

  defp eval_if(lhs, ">", rhs) when lhs > rhs, do: {:ok, true}
  defp eval_if(_lhs, ">", _rhs), do: {:ok, false}

  defp eval_if(lhs, "<", rhs) when lhs < rhs, do: {:ok, true}
  defp eval_if(_lhs, "<", _rhs), do: {:ok, false}

  defp eval_if(lhs, "==", rhs) when lhs == rhs, do: {:ok, true}
  defp eval_if(_lhs, "==", _rhs), do: {:ok, false}

  defp eval_if(lhs, "!=", rhs) when lhs != rhs, do: {:ok, true}
  defp eval_if(_lhs, "!=", _rhs), do: {:ok, false}
end
