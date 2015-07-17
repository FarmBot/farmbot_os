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
      duck :bot, methods: [:status, :mesh, :template_variables]
    end

    def execute
      TelemetryMessage.build(template).publish(bot.mesh)
    end

  private

    def template
      @template ||= Liquid::Template
                      .parse(message)
                      .render(bot.template_variables)
    end
  end
end
