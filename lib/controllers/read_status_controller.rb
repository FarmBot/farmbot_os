require_relative 'abstract_controller'

class ReadStatusController < AbstractController
  def call
    reply "read_status", info
  end

  def info
    info = {busy: bot.status[:busy], current_command: bot.status[:last]}
    info.merge(pin_info).merge(axis_info)
  end

  def pin_info
    # Performs lazy evaluation of pin status. If the pin status is 'unknown',
    # performs a lookup for next status poll. Otherwise, uses cached value.
    [*0..13].inject({}) do |hsh, pin|
      hsh["pin#{pin}".to_sym] = status_of(pin)
      maybe_read_pin(pin)
      hsh
    end
  end

  def axis_info
    {x: bot.status[:x], y: bot.status[:y], z: bot.status[:z]}
  end

  def status_of(pin)
    bot.status.pin(pin)
  end

  def maybe_read_pin(pin)
    bot.commands.read_parameter(pin) if status_of(pin) == :unknown
  end
end
