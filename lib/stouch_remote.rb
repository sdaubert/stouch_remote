# frozen_string_literal: true

require 'stouch_remote/version'

module STouchRemote
  # Base error class
  class Error < StandardError; end

  # Cannot connect to SundTouch device
  class CannotConnectError < Error; end
end

require_relative 'stouch_remote/connection'
