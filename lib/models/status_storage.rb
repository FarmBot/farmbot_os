require 'pstore'
# Farmbot needs a way to persist some variables across reboots.
# We have SQLite, but sometimes its overkill for these use cases.
# One example is the bot's current X, Y, Z coords. We need to know the bot's
# position when powering down, and saving it to SQL is a lot of work for simple
# key/value pairs. This is where PStore (and the StatusStorage class) come in.
# StatusStorage is child of Ruby's `PStore` class, which allows you to create
# hash-like objects that are stored to disk (*.pstore). Farmbot uses that to
# remember settings after reboots.
# THE NAMESPACE STUFF IS JUST A PREMETIVE MEASURE. I CHANGED THE API, BUT NOT
# IMPLEMENTATION. In the future, we can actually namespace them internally if
# need be. Had to disable it temporarily while debugging. RC 08/2015.
module FBPi
  class StatusStorage < PStore
    class InvalidNamespace < Exception; end

    NAMESPACES = {
      bot:  "Used for storage of Arduino specific settings, like the status "\
            "register object inside the Arduino.",
      pi:   "Used for storage of Raspberry-Pi specific settings, such as the "\
            "time of :last_sync.",
      misc: "Anything else."
    }

    # Human readable explanation for use in exceptions
    NAMESPACE_EXPLANATIONS = NAMESPACES
      .inject("\n") { |a, (k, v)| a += "#{k.inspect} => #{v}\n" }

    def initialize(*args)
      super
      transaction { |i| set_namespaces(i) }
    end

    # Creates namespaces (hashes) in the store if it has not yet been set.
    def set_namespaces(info)
      NAMESPACES.keys.each { |k| if info[k] then nil else info[k] = {} end }
    end


    def update_attributes(namespace = :none, hash)
      validate_namespace(namespace)
      hash.each do |key, value|
        transaction { self[namespace].merge!(key => value) }
      end
    end

    def fetch(namespace = :none, key)
      validate_namespace(namespace)
      transaction { self[namespace][key] }
    end

    def to_h(namespace = :none)
      validate_namespace(namespace)
      transaction do
        self[namespace]
          .keys
          .reduce({}) { |hash, root| hash[root] = self[namespace][root]; hash }
      end
    end

  private

    def validate_namespace(namespace)
      return if NAMESPACES.keys.include?(namespace)
      raise InvalidNamespace, """You tried to access a status_storage namespace\
      of '#{namespace}' while accessing `StatusStorage`. Try one of these\
      instead:#{NAMESPACE_EXPLANATIONS}""".squeeze(" ")
    end
  end
end
