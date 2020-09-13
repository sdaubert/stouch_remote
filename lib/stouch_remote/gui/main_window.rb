# frozen_string_literal: true

module STouchRemote
  class Gui
    class MainWindow < Gtk::ApplicationWindow
      attr_reader :conn

      type_register

      class <<self
        def init
          set_template data: File.read(File.join(__dir__, 'main_window.ui'))

          bind_template_child 'connect_menuitem'
          bind_template_child 'deconnect_menuitem'
          bind_template_child 'quit_menuitem'
          bind_template_child 'about_menuitem'
          bind_template_child 'device_name_label'
          bind_template_child 'main_grid'
          bind_template_child 'prev_button'
          bind_template_child 'play_pause_button'
          bind_template_child 'next_button'
          bind_template_child 'title_label'
          bind_template_child 'title_image'
          bind_template_child 'info_label'
          bind_template_child 'volume_button'
        end
      end

      def initialize(application, conn)
        super application: application

        @conn = conn
        @source = nil
        @account = nil
        @art_url = nil

        connect_menuitem.signal_connect 'activate' do
          on_connect
        end
        quit_menuitem.signal_connect 'activate' do
          on_quit
        end

        about_menuitem.signal_connect 'activate' do
          Gui::AboutDialog.new.show_all
        end
      end

      def set_source(type, track: nil, artist: nil, album: nil, art_url: nil)
        case type
        when :standby
          title_label.text = 'No title'
          title_image.stock = Gtk::Stock::MISSING_IMAGE
        when :playing
          label = "<b>#{track}</b>\n#{artist}\n#{album}"
          title_label.markup = label
          cache_art_url(art_url, artist: artist, album: album)
        end
      end

      def info(text)
        info_label.text = text
        application.logger.info { text }
      end

      def warn(text)
        info_label.markup = "<span fgcolor=\"#ff7f7f\" font_weight=\"bold\">#{text}</span>"
        application.logger.warn { text }
      end

      def on_connect
        conn.start
        conn.send('info')
        conn.send('volume')
        conn.send('now_playing')
        info('Connected to %s' % conn.name)
        application.connected = true

        conn.wait_async_events
      rescue SystemCallError
        warn('cannot connect to %s' % conn.url)
        device_name_label.text = 'None'
        application.connected = false
      end

      def on_quit
        application.quit
      end

      private

      def cache_art_url(art_url, artist:, album:)
        return if @art_url == art_url

        conn.logger.info { 'Download art at %s' % art_url }
        @art_url = art_url
        fname = Utils.download(art_url, basename: "#{artist}-#{album}")
        conn.logger.debug { 'Download to %s' % fname }
        title_image.set_from_file(fname)
      end
    end
  end
end
