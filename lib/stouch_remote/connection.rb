# frozen_string_literal: true

require 'websocket/driver'
require 'nokogiri'
require 'socket'
require 'logger'
require 'thread'

require_relative 'connection/base_handler'

module STouchRemote
  class Connection
    # URL to connect to
    # @return [String]
    attr_reader :url

    # Websocket driver
    # @return [Websocket::Driver]
    attr_reader :driver

    # TCP socket
    # @return [TCPSocket]
    attr_reader :socket

    # SoudTouch device ID
    # @return [nil,String]
    attr_accessor :device_id

    # SoundTouch device name
    # @return [String]
    attr_accessor :name

    # @return [Logger]
    attr_reader :logger

    # @return [Connection::BaseHandler]
    attr_reader :handler

    # @private maximum bytes to receive from TCP socket
    MAXRECV = 2048

    # @private Message to send format
    MSG = '<msg><header deviceID="%s" url="%s" method="%s">' \
          '<request requestID="%d"><info %s type="%s"/>%s</request>' \
          '</header>%s</msg>'

    # @param [String] host
    # @param [Integer] port
    # @param [Hash] opts
    # @options opts [Logger] :logger
    # @options opts [:debug, :info, :warn, :error] :logger_severity
    def initialize(host, port, opts={})
      @host = host
      @port = port
      @url = 'ws://%s:%u' % [host, port]
      @req_id = 1
      @device_id = nil
      @name = 'No device'
      @driver = WebSocket::Driver.client(self, protocols: ['gabbo'])
      @logger = initialize_logger(opts)
      @handler = Connection::BaseHandler.new(self)
    end

    # Start and intialize connection to SoundTouch device
    # @param [Proc] message_cb callback on new message received
    # @param [Proc] error_cb callback on error
    # @param [Proc] close_cb callback on websocket closing
    # @return [self]
    # @raise [CannotConnectError]
    def start
      @socket = TCPSocket.new(@host, @port)
      @socket_mutex = Mutex.new

      set_callbacks
      handshake
      sleep 0.2

      self
    end

    # @private Method needed by Websocket::Driver
    # @param [String] data data to send over {#socket}
    # @return [void]
    def write(data)
      @socket_mutex.synchronize { socket.send(data, 0) }
    end

    # Send a request
    # @param [String] url
    # @param [String] request
    # @param [String] info
    # @param [String] type
    # @param [String] body
    # @return [String]
    def send(url, request: '', info: '', type: 'new', body: '', async: false)
      msg = MSG % [device_id, url, method(body), req_id, info,
                   type, request, to_body(body)]

      logger.debug { 'Send message: %s' % msg }
      status = driver.text(msg)
      logger.debug { 'Send status: %s' % status }

      return if async

      logger.debug { 'Get data from TCP socket' }
      receive
    end

    def wait_async_events
      @thread = Thread.new do
        loop do
          receive(nonblock: true)
          sleep 1
        rescue StandardError => e
          logger.warn { e.to_s }
          retry
        end
      end
    end

    def receive(nonblock: false)
      data = @socket_mutex.synchronize do
        if nonblock
          socket.recv_nonblock(MAXRECV)
        else
          socket.recv(MAXRECV)
        end
      end

      logger.debug { 'Got (%u): %s' % [data.size, data.inspect] }
      driver.parse(data)
    rescue IO::WaitReadable
      sleep 1
    end

    # Set handler
    # @param [Class] handler
    # @return [void]
    def handler=(handler)
      @handler = handler.new(self)
      set_callbacks
    end

    def close
      @thread.kill
      driver.close
    end

    def volume(value=nil, async: false)
      return send('volume', async: async) if value.nil?

      # send('volume', info: 'mainNode="volume"', body: "<volume>#{value}</volume>", async: async)
      send('volume', body: "<volume>#{value}</volume>", async: async)
    end

    def play_pause
      key 'PLAY_PAUSE'
    end

    def next_track
      key 'NEXT_TRACK'
    end

    def prev_track
      key 'PREV_TRACK'
    end

    private

    def key(name, state: 'press')
      send('key', body: '<key state="%s" sender="Gabbo">%s</key>' % [state, name])
    end

    def initialize_logger(opts={})
      logger = opts[:logger] || Logger.new(STDOUT)
      unless opts[:logger]
        severity = Logger::Severity.const_get((opts[:logger_severity] || :warn).to_s.upcase)
        logger.level = severity
      end

      logger
    end

    def set_callbacks
      driver.on(:message) { |e| @handler.on_message(e) }
      driver.on(:error) { |e| @handler.on_error(e) }
      driver.on(:close) { |e| @handler.on_close(e) }
    end

    def handshake
      logger.debug { "Starting websocket to #{@url}" }
      driver.start
      sleep 0.2

      handshake = socket.recv(MAXRECV)
      logger.debug('Handshake response: %s' % handshake)

      driver.parse(handshake)
      logger.debug('Driver state: %s' % driver.state)
      raise CannotConnectError unless driver.state == :open
    end

    def method(body)
      (body.length > 5) && 'POST' || 'GET'
    end

    def to_body(body)
      return "<body>#{body}</body>" if body.length > 5

      ''
    end

    def req_id
      id = @req_id
      @req_id += 1

      id
    end
  end
end
