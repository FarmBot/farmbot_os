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
      duck :bot, methods: [:status, :mesh]
    end

    def execute
      TelemetryMessage.build(template).publish(bot.mesh)
    end

  private

    def allowed_template_vars
      bot
        .status
        .to_h
        .reduce({}){ |a, (b, c)| a[b.to_s.downcase] = c; a}
        .tap { |h| h['pins'].map { |k, v| h["pin#{k}"] = v.to_s } }
        .merge('time' => Time.now)
    end

    def template
      @template ||= Liquid::Template
                      .parse(message)
                      .render(allowed_template_vars)
    end
  end
end
