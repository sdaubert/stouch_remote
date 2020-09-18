# frozen_string_literal: true

module STouchRemote
  # Module to handle various data objects
  module Data
    Playing = Struct.new(:status, :track, :artist, :album, :art_url, :forward_enabled, :backward_enabled, :time, :total_time)
  end
end
