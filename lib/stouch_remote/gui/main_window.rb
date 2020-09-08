require 'gtk3'

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
          bind_template_child 'main_spinner'
          bind_template_child 'info_label'
        end
      end

      def initialize(application, conn)
        super application: application

        @conn = conn

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

      def set_source(type, label: nil, image: nil)
        case type
        when :standby
          title_label.text = 'No title'
          title_image.stock = Gtk::Stock::MISSING_IMAGE
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
        info_label.text = 'Connecting...'
        main_spinner.start

        begin
          conn.start
          conn.send('info')
          conn.send('now_playing')
          info('Connected to %s' % conn.device_id)

          application.connected = true
        rescue SystemCallError
          warn('cannot connect to %s' % conn.url)
          device_name_label.text = 'None'
          application.connected = false
        end

        main_spinner.stop
      end

      def on_quit
        application.quit
      end
    end
  end
end
