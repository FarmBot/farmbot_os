require 'pstore'

module FBPi
  # The bot will forget where it is if you power it off unexpectedly. We fix this
  # by storing all of the status registers in a *.pstore file and reloading on
  # start.
  class StatusStorage < PStore
    def update_attributes(hash)
      hash.each do |key, value|
        transaction { self[key] = value }
      end
    end

    def fetch(key)
      transaction { self[key] }
    end

    def to_h
      transaction do
        keys  = self.roots
        keys.reduce({}) { |hash, root| hash[root] = self[root]; hash }
      end
    end
  end
end
