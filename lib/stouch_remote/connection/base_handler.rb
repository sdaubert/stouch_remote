# frozen_string_literal: true
module STouchRemote
  class Connection
    class BaseHandler
      attr_reader :conn

      def initialize(conn)
        @conn = conn
      end

      def on_message(e)
        conn.logger.info { "on_message: #{e.inspect}" }
        return if e.data.start_with?('<SoundTouchSdkInfo')

        msg = Nokogiri::XML(e.data)
        hdr = msg.xpath('//header').first
        return if hdr.nil?  # TODO: update messages: <updates deviceID="1893D7EE6116"><nowPlayingUpdated><nowPlaying deviceID="1893D7EE6116" source="DEEZER" sourceAccount="12018039"><ContentItem source="DEEZER" type="tracklistRadio" location="https://api.deezer.com/user/me/flow" sourceAccount="12018039" isPresetable="true"><itemName>##TRANS_flow##</itemName></ContentItem><track>Bonne Humeur</track><artist>La chanson du dimanche</artist><album>Plante Un Arbre</album><stationName>##TRANS_flow##</stationName><art artImageStatus="IMAGE_PRESENT">https://api.deezer.com/album/278166/image?size=big</art><time total="164">0</time><rating>NONE</rating><skipEnabled /><playStatus>BUFFERING_STATE</playStatus><seekSupported value="true" /><streamType>RADIO_TRACKS</streamType><artistID>17258</artistID><trackID>2863860</trackID></nowPlaying></nowPlayingUpdated></updates>

        case hdr['url']
        when 'info'
          info(msg)
        #when 'now_playing'
        #  now_playing(msg)
        #when 'volume'
        #  volume(msg)
        end
      end

      def on_error(e)
        conn.logger.warning { "on_error: #{e.inspect}" }
      end

      def on_close(e)
        conn.logger.warning { "on_close: #{e.inspect}" }
      end

      def info(xml); end
    end
  end
end