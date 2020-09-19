# frozen_string_literal: true

module STouchRemote
  class Connection
    class BaseHandler
      attr_reader :conn

      def initialize(conn)
        @conn = conn
      end

      def on_message(event)
        conn.logger.debug { "on_message: #{event.inspect}" }
        return if event.data.start_with?('<SoundTouchSdkInfo')

        msg = Nokogiri::XML(event.data)
        node = msg.xpath('//header')
        return dispatch(msg) if node

        node = msg.xpath('/updates')
        return if node.nil?

        conn.logger.info { 'Update received: %s' % node.children.first.name }
        dispatch(msg)
      end

      def on_error(event)
        conn.logger.warn { "on_error: #{event.inspect}" }
      end

      def on_close(event)
        conn.logger.warn { "on_close: #{event.inspect}" }
      end

      def info(xml); end

      def now_playing(xml); end

      def volume(xml); end

      private

      def dispatch(xml)
        return now_playing(xml) unless xml.xpath('//nowPlaying').empty?
        return volume(xml) unless xml.xpath('//volume').empty?
        return info(xml) if xml.xpath('//info').size > 1
      end
    end
  end
end
