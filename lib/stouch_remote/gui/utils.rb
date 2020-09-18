# frozen_string_literal: true

require 'uri'
require 'fileutils'
require 'httparty'

module STouchRemote
  # Base directory to save files
  SAVE_DIR = '/tmp'
  # Prefix of saved files
  PREFIX = 'stouch-remote-'

  module Utils
    # Download +url+ and save it on disk
    # @param [String] url
    # @return [String] filename of newly created file
    def self.download(url, basename: nil)
      uri = URI(url)
      basename ||= uri.path.split('/').last
      basename = basename.tr(' ', '_')
      fname = File.join(SAVE_DIR, "#{PREFIX}#{basename}")
      puts "fname: #{fname}"

      resp = HTTParty.get(uri)
      p resp.code
      return nil if resp.code != 200

      File.open(fname, 'wb') do |file|
        file.write(resp.body)
      end

      fname
    end

    # Remove files older than +older+ seconds
    # @param [Integer] older
    # @return [void]
    def self.clean_up_art_files(older)
      limit = Time.now - older
      Dir.glob(File.join(SAVE_DIR, "#{PREFIX}*")).each do |file|
        FileUtils.rm(file, force: true) if File.stat(file).ctime < limit
      end
    end
  end
end
