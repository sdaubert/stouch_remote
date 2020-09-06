# frozen_string_literal: true

require 'websocket/driver'
require 'nokogiri'
require 'socket'
require 'logger'

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

    # @return [Logger]
    attr_reader :logger

    # @private maximum bytes to receive from TCP socket
    MAXRECV = 2048

    # @private Message to send format
    MSG = '<msg><header deviceID="%<device_id>s" url="%<url>s" method="%<method>s">' +
          '<request requestID="%<req_id>d"><info %<info>s type="%<type>s"/></request>' +
          '</header>%<body>s</msg>'

    # @param [String] host
    # @param [Integer] port
    # @param [Hash] opts
    # @options opts [Logger] :logger
    # @options opts [:debug, :info, :warn, :error] :logger_severity
    def initialize(host, port, opts={})
      @url = 'ws://%s:%u' % [host, port]
      @req_id = 1
      @device_id = nil
      @driver = WebSocket::Driver.client(self, protocols: ['gabbo'])
      @socket = TCPSocket.new(host, port)
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
      set_callbacks
      handshake
      sleep 0.2

      self
    end

    # @private Method needed by Websocket::Driver
    # @param [String] data data to send over {#socket}
    # @return [void]
    def write(data)
      socket.send(data, 0)
    end

    # Send a request
    # @param [String] url
    # @param [String] request
    # @param [String] info
    # @param [String] type
    # @param [String] body
    # @return [String]
    def send(url, request: '', info: '', type: 'new', body: '')
      msg = MSG % { device_id: device_id, url: url, method: method(body),
                    req_id: req_id, request: request, info: info, type: type,
                    body: to_body(body) }

      logger.debug { 'Send message: %s' % msg }
      status = driver.text(msg)
      logger.debug { 'Send statud: %s' % status }
      sleep 1

      logger.debug { 'Get dat from TCP socket' }
      data = socket.recv(MAXRECV)
      logger.debug { 'Got (%u): %s' % [data.size, data.inspect] }
      driver.parse(data)
    end

    # Set handler
    # @param [Class] handler
    # @return [void]
    def set_handler(handler)
      @handler = handler.new(self)
    end

    def close
      driver.close
    end

    private

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
      logger.debug("Handshake response: %s" % handshake)

      driver.parse(handshake)
      logger.debug("Driver state: %s" % driver.state)
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
