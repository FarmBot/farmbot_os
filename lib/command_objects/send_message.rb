require 'mutations'
require 'liquid'
require_relative '../telemetry_message'

module FBPi
  # Sends a message to MeshBlu with optional Liquid Templating. Usually this is
  # required to report an event, completion of a schedule or system failures.
  class SendMessage < Mutations::Command
    Liquid::Template.error_mode = :lax

    required do
      string :message
      duck :mesh, methods: [:data]
      duck :bot, methods: [:to_h]
    end

    def execute
      TelemetryMessage.build(template).publish(mesh)
    end

  private

    def allowed_template_vars
      # What do all the PINs look like? Are they nested? Need to keep it flat.
      bot.to_h.merge('time' => Time.now)
    end

    def template
      @template ||= Liquid::Template.parse(message).render allowed_template_vars
    end
  end
end
