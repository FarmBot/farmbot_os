alias Farmbot.Asset.PinBinding
defimpl String.Chars, for: PinBinding do
  def to_string(%PinBinding{pin_num: 16}) do
    "Button 1"
  end

  def to_string(%PinBinding{pin_num: 22}) do
    "Button 2"
  end

  def to_string(%PinBinding{pin_num: 26}) do
    "Button 3"
  end

  def to_string(%PinBinding{pin_num: 5}) do
    "Button 4"
  end

  def to_string(%PinBinding{pin_num: 20}) do
    "Button 5"
  end

  def to_string(%PinBinding{pin_num: num}) do
    "Pi GPIO #{num}"
  end
end
