class HardwareInterfaceArduinoValuesReceived

  attr_accessor :p , :v
  attr_accessor :x , :y , :z
  attr_accessor :xa, :xb
  attr_accessor :ya, :yb
  attr_accessor :za, :zb


  def initialize

    @p  = -1
    @v  = 0
    @x  = 0
    @y  = 0
    @z  = 0
    @xa = 0
    @xb = 0
    @ya = 0
    @yb = 0
    @za = 0
    @zb = 0

  end

  def load_parameter(name, value)

    case name
      when 'P'
        @p  = value
      when 'V'
        @v  = value
      when 'XA'
        @xa = value
      when 'XB'
        @xb = value
      when 'YA'
        @ya = value
      when 'YB'
        @yb = value
      when 'ZA'
        @za = value
      when 'ZB'
        @zb = value
      when 'X'
        @x  = value
      when 'Y'
        @y  = value
      when 'Z'
        @z  = value
    end
  end

end
