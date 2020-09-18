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
          bind_template_child 'time_progressbar'
          bind_template_child 'elapsed_time_label'
          bind_template_child 'total_time_label'
        end
      end

      def initialize(application, conn)
        super application: application

        @conn = conn
        @source = nil
        @account = nil
        @art_url = nil
        @do_not_reemit_volume = false
        @playing = false
        @playing_timeout = nil
        @playing_data = Data::Playing.new

        connect_menu
        connect_volume
        connect_play_buttons
      end

      def playing?
        @playing
      end

      def playing=(val)
        @playing = val

        if @playing_timeout.nil? && playing?
          @playing_timeout = GLib::Timeout.add(1000) do
            return false unless playing?

            @playing_data.time += 1
            handle_time
          end
        elsif !playing?
          @playing_timeout = nil
        end

        true
      end

      def set_source(type, data: nil)
        @playing_data = data

        case type
        when :standby
          title_label.text = 'No title'
          title_image.stock = Gtk::Stock::MISSING_IMAGE
          play_pause_button.child.stock = Gtk::Stock::MEDIA_PLAY
          self.playing = false
        when :playing, :pause
          label = "<b>#{data.track}</b>\n#{data.artist}\n#{data.album}"
          title_label.markup = label
          play_pause_button.child.stock = if type == :pause
                                            self.playing = false
                                            Gtk::Stock::MEDIA_PLAY
                                          else
                                            self.playing = true
                                            Gtk::Stock::MEDIA_PAUSE
                                          end
          handle_navigation_buttons
          handle_time
          cache_art_url
        end
      end

      def info(text)
        info_label.text = text
        application.logger.info { text }
      end

      def volume_button_value=(value)
        @do_not_reemit_volume = true
        volume_button.value = value
        @do_not_reemit_volume = false
      end

      def warn(text)
        info_label.markup = "<span fgcolor=\"#ff7f7f\" font_weight=\"bold\">#{text}</span>"
        application.logger.warn { text }
      end

      def on_connect
        conn.start
        conn.send('info')
        conn.volume
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

      def on_volume_changed(value)
        return if @do_not_reemit_volume

        conn.volume(value, async: true)
      end

      def on_play_pause_clicked
        conn.play_pause
      end

      def on_prev_clicked
        conn.prev_track
      end

      def on_next_clicked
        conn.next_track
      end

      private

      def connect_menu
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

      def connect_volume
        volume_button.signal_connect 'value-changed' do |_button, value|
          on_volume_changed(value.to_i)
        end
      end

      def connect_play_buttons
        play_pause_button.signal_connect 'clicked' do
          on_play_pause_clicked
        end
        prev_button.signal_connect 'clicked' do
          on_prev_clicked
        end
        next_button.signal_connect 'clicked' do
          on_next_clicked
        end
      end

      def cache_art_url
        data = @playing_data
        return if @art_url == data.art_url

        conn.logger.info { 'Download art at %s' % data.art_url }
        @art_url = data.art_url
        fname = Utils.download(data.art_url, basename: "#{data.artist}-#{data.album}")
        conn.logger.debug { 'Download to %s' % fname }
        title_image.set_from_file(fname)
      end

      def handle_navigation_buttons
        prev_button.sensitive = @playing_data.backward_enabled
        next_button.sensitive = @playing_data.forward_enabled
      end

      def handle_time
        elapsed_time_label.text = data_to_time(@playing_data.time)
        total_time_label.text = data_to_time(@playing_data.total_time)
        time_progressbar.fraction = @playing_data.time.to_f / @playing_data.total_time
      end

      def data_to_time(value)
        hour = value / 3600
        min, sec = value.divmod(60)

        if hour > 0
          '%02u:%02u:%02u' % [hour, min, sec]
        else
          '%02u:%02u' % [min, sec]
        end
      end
    end
  end
end
