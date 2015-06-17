require 'settingslogic'
module FBPi
  class Settings < Settingslogic
    source "settings.yml"
    namespace ENV['FBENV'] || 'production'
  end
end
