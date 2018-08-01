defmodule Farmbot.OS.IOLayer.If do
  alias Farmbot.CeleryScript.AST
  alias Farmbot.Asset
  alias Asset.{Peripheral, Sensor}

  def execute(%{lhs: lhs, op: op, rhs: rhs}, _body) do
    left = eval_lhs(lhs)
    cond do
      is_number(left) or is_nil(left) -> eval_if(left, op, rhs)
      match?({:error, _}, left) -> left
    end
  end

  defp eval_lhs(axis) when axis in ["x", "y", "z"] do
    Farmbot.Firmware.get_current_position()
    |> Enum.find(fn({a, _}) -> axis == to_string(a) end)
    |> elem(1)
  end

  # handles looking up a pin from a peripheral.
  defp eval_lhs(%AST{kind: :named_pin} = named_pin) do
    id = named_pin.args.pin_id
    type = named_pin.args.pin_type
    case fetch_resource(type, id) do
      {:ok, number} ->
        eval_lhs({:pin, number})
      {:error, reason} when is_binary(reason) -> {:error, reason}
    end
  end

  defp eval_lhs({:pin, pin}) do
    case Farmbot.Firmware.get_pin_value(pin) do
      %{value: value} -> value
      nil -> {:error, "Could not find firmware pin value #{pin}"}
    end
  end

  defp eval_if(nil, "is_undefined", _), do: {:ok, true}
  defp eval_if(_,   "is_undefined", _), do: {:ok, false}
  defp eval_if(nil, _, _),
    do: {:error, "Could not eval IF because left hand side of if statement is undefined."}

  defp eval_if(lhs, ">", rhs) when lhs > rhs, do: {:ok, true}
  defp eval_if(_lhs, ">", _rhs), do: {:ok, false}

  defp eval_if(lhs, "<", rhs) when lhs < rhs, do: {:ok, true}
  defp eval_if(_lhs, "<", _rhs), do: {:ok, false}

  defp eval_if(lhs, "is", rhs) when lhs == rhs, do: {:ok, true}
  defp eval_if(_lhs, "is", _rhs), do: {:ok, false}

  defp eval_if(lhs, "not", rhs) when lhs != rhs, do: {:ok, true}
  defp eval_if(_lhs, "not", _rhs), do: {:ok, false}
  defp eval_if(_, op, _), do: {:error, "Unknown operator: #{op}"}

  defp fetch_resource("Peripheral", id) do
    case Asset.get_peripheral_by_id(id) do
      %Peripheral{pin: number} -> {:ok, number}
      nil -> {:error, "Could not find Peripheral by id: #{id}"}
    end
  end

  defp fetch_resource("Sensor", id) do
    case Asset.get_sensor_by_id(id) do
      %Sensor{pin: number} -> {:ok, number}
      nil -> {:error, "Could not find Sensor by id: #{id}"}
    end
  end
end
