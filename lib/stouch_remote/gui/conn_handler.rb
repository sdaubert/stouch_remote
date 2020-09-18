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
        app.source.source = source
        app.source.account = now_playing['sourceAccount']

        case source
        when 'STANDBY'
          app.main_window.set_source(:standby)
        when 'DEEZER'
          data = now_playing_data(now_playing)

          app.main_window.set_source(data.status, data: data)
        end
      end

      def volume(xml)
        volume = xml.xpath('//volume').first
        value = (volume > 'actualvolume').text.to_i
        conn.logger.info { 'Volume at %u' % value }

        app.main_window.volume_button_value = value
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

      def now_playing_data(xml)
        track = (xml > 'track').text
        artist = (xml > 'artist').text
        album = (xml > 'album').text
        art_url = (xml > 'art').text
        status = (xml > 'playStatus').text == 'PAUSE_STATE' ? :pause : :playing

        forward_enabled = !(xml > 'skipEnabled').empty?
        backward_enabled = !(xml > 'skipPreviousEnabled').empty?

        Data::Playing.new(status, track, artist, album, art_url, forward_enabled, backward_enabled)
      end
    end
  end
end
