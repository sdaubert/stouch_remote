# frozen_string_literal: true

module STouchRemote
  class Gui
    class ConnHandler < Connection::BaseHandler
      attr_accessor :app

      def info(xml)
        app.logger.debug { "#{self.class}#info" }
        get_device_id(xml) if conn.device_id.nil?

        type = xml.xpath('//type').first.text
        ipaddr = xml.xpath('//ipAddress').first.text

        # device_name = "#{name} (type: #{type}, id: #{conn.device_id})"
        device_name = "#{conn.name} (#{ipaddr})"
        app.logger.debug { 'Device name: %s' % device_name }
        app.main_window.device_name_label.text = device_name
      end

      def now_playing(xml)
        app.logger.debug { "#{self.class}#now_playing" }

        now_playing = xml.xpath('//nowPlaying').first
        source = now_playing['source']
        app.data.source = source
        app.data.account = now_playing['sourceAccount']

        case source
        when 'STANDBY'
          app.main_window.set_source(:standby)
        when 'DEEZER'
          track = (now_playing > 'track').text
          artist = (now_playing > 'artist').text
          album = (now_playing > 'album').text
          art_url = (now_playing > 'art').text

          app.main_window.set_source(:playing, track: track, artist: artist, album: album, art_url: art_url)
        end
      end

      private

      def get_device_id(xml)
        app.logger.debug { 'Get deviceID' }

        info = xml.xpath('//info')[1]
        conn.device_id = info['deviceID']

        name = xml.xpath('//name').first.text
        conn.name = name

        app.logger.debug { 'deviceID: %s' % conn.device_id }
      end
    end
  end
end
