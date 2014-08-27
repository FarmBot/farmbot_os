module SocketIO
  module Client
    module Simple

      def self.connect(url, opts={})
        client = Client.new(url, opts)
        client.connect
        client
      end

      class Client
        include EventEmitter
        alias_method :__emit, :emit

        attr_reader :websocket, :session_id, :heartbeat_timeout,
                    :connection_timeout, :transports, :url
        attr_accessor :last_heartbeat_at, :reconnecting

        def initialize(url, opts={})
          @url = url
          @opts = opts
          @reconnecting = false

          Thread.new do
            loop do
              sleep 5
              next if !@last_heartbeat_at or !@heartbeat_timeout
              if Time.now - @last_heartbeat_at > @heartbeat_timeout
                @websocket.close
                __emit :disconnect
                reconnect
              end
            end
          end

        end

        def connect
          res = nil
          begin
            res = HTTParty.get "#{@url}/socket.io/1/"
          rescue Errno::ECONNREFUSED => e
            @reconnecting = false
            reconnect
            return
          end
          raise res.body unless res.code == 200

          arr = res.body.split(':')
          @session_id = arr.shift
          @heartbeat_timeout = arr.shift.to_i
          @connection_timeout = arr.shift.to_i
          @transports = arr.shift.split(',')
          unless @transports.include? 'websocket'
            raise Error, "server #{@url} does not supports websocket!!"
          end
          begin
            @websocket = WebSocket::Client::Simple.connect "#{@url}/socket.io/1/websocket/#{@session_id}"
          rescue Errno::ECONNREFUSED => e
            @reconnecting = false
            reconnect
            return
          end

          this = self
          @websocket.on :error do |err|
            this.__emit :error, err
          end

          @websocket.on :message do |msg|
            code, body = msg.data.scan(/^(\d+):{0,1}[+.0-9]*:{0,2}(.*)$/)[0]
            code = code.to_i
            case code
            when 0
              this.websocket.close if this.websocket.open?
              this.__emit :disconnect
              this.reconnect
            when 1  ##  socket.io connect
              this.last_heartbeat_at = Time.now
              this.reconnecting = false
              this.__emit :connect
            when 2
              this.last_heartbeat_at = Time.now
              send "2::"  # socket.io heartbeat
            when 3
            when 4
            when 5
              data = JSON.parse body
              this.__emit data['name'], *data['args']
            when 6
            when 7
              this.__emit :error
            end
          end

          @websocket.send "1::#{@opts[:path]}"

          return
        end

        def reconnect
          return if @reconnecting
          @reconnecting = true
          sleep rand(20)+20
          connect
        end

        def open?
          @websocket and @websocket.open?
        end

        def emit(event_name, *data)
          return unless open?
          emit_data = {:name => event_name, :args => data}.to_json
          @websocket.send "5:::#{emit_data}"
        end
      end
    end
  end
end
