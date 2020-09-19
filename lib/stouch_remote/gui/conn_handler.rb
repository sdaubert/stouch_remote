# frozen_string_literal: true

module STouchRemote
  class Gui
    class ConnHandler < Connection::BaseHandler
      attr_accessor :app

      private

      def info(xml)
        app.logger.debug { "#{self.class}#info" }
        get_device_id(xml) if conn.device_id.nil?

        ipaddr = xml.xpath('//ipAddress').first.text
        device_name = "#{conn.name} (#{ipaddr})"

        conn.logger.debug { 'Device name: %s' % device_name }
        app.main_window.device_name_label.text = device_name
      end

      def now_playing(xml)
        conn.logger.debug { "#{self.class}#now_playing" }

        now_playing = xml.xpath('//nowPlaying').first
        source = now_playing['source']
        app.source.source = source
        app.source.account = now_playing['sourceAccount']

        case source
        when 'INVALID_SOURCE', 'STANDBY'
          app.main_window.status = :standby
        when 'DEEZER'
          status = handle_now_playing_data(now_playing)
          app.main_window.status = status
        end
      end

      def volume(xml)
        volume = xml.xpath('//volume').first
        value = (volume > 'actualvolume').text.to_i
        conn.logger.info { 'Volume at %u' % value }

        app.main_window.volume_button_value = value
      end

      def get_device_id(xml)
        app.logger.debug { 'Get deviceID' }

        info = xml.xpath('//info')[1]
        conn.device_id = info['deviceID']

        name = xml.xpath('//name').first.text
        conn.name = name

        conn.logger.debug { 'deviceID: %s' % conn.device_id }
      end

      def handle_now_playing_data(xml)
        data = app.playing_data
        track_id = (xml > 'trackID').text.to_i
        data.status = get_status(xml)
        data.time, data.total_time = get_time(xml)

        return data.status if data.track_id == track_id

        data.track_id = track_id
        track_data(data, xml)
        nav_data(data, xml)

        conn.logger.info { "now playing #{data.track} (#{data.album}) - #{data.artist}" }

        data.status
      end

      def track_data(data, xml)
        data.track = escape_ampersand(from_xml_node(xml, 'track'))
        data.artist = escape_ampersand(from_xml_node(xml, 'artist'))
        data.album = escape_ampersand(from_xml_node(xml, 'album'))
        data.art_url = from_xml_node(xml, 'art')
      end

      def nav_data(data, xml)
        data.forward_enabled = node_present?(xml, 'skipEnabled')
        data.backward_enabled = node_present?(xml, 'skipPreviousEnabled')
      end

      def escape_ampersand(text)
        text.gsub!(/&/, '&amp;')
        text
      end

      def from_xml_node(xml, node_name)
        (xml > node_name).text
      end

      def node_present?(xml, node_name)
        !(xml > node_name).empty?
      end

      def get_time(xml)
        time_node = (xml > 'time').last
        elapsed = time_node.text.to_i
        total = time_node['total'].to_i

        [elapsed, total]
      end

      def get_status(xml)
        from_xml_node(xml, 'playStatus') == 'PAUSE_STATE' ? :pause : :playing
      end
    end
  end
end
