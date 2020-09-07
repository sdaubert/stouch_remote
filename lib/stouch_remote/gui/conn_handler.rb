# frozen_string_literal: true

module STouchRemote
  class Gui
    class ConnHandler < Connection::BaseHandler
      attr_accessor :app

      def info(xml)
        if conn.device_id.nil?
          info = xml.xpath('//info')[1]
          conn.device_id = info['deviceID']
        end
        name = xml.xpath('//name').first.text
        type = xml.xpath('//type').first.text
        ipaddr = xml.xpath('//ipAddress').first.text

        #device_name = "#{name} (type: #{type}, id: #{conn.device_id})"
        device_name = "#{name} (#{ipaddr})"
        conn.logger.info { 'Device: %s' % device_name }
        app.main_window.device_name_label.text = device_name
      end

      def now_playing(xml)
        now_playing = xml.xpath('//nowPlaying').first
        source = now_playing['source']

        case source
        when 'STANDBY'
          app.main_window.set_source(:standby)
        end
      end
    end
  end
end
