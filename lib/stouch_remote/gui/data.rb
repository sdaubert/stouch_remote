# frozen_string_literal: true

module STouchRemote
  # Module to handle various data objects
  module Data
  end
end

Dir.glob(File.join(__dir__, 'data', '*.rb')).each { |f| require_relative f }