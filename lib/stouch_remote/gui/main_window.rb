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
          bind_template_child 'progressbar'
          bind_template_child 'prev_button'
          bind_template_child 'play_pause_button'
          bind_template_child 'next_button'
          bind_template_child 'title_label'
          bind_template_child 'title_image'
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

      def set_source(type, label:, image:)
        case type
        when :standby
          title_label.text = 'No title'
          title_image.stock = Gtk::Stock::MISSING_IMAGE
        end
      end

      def on_connect
        conn.start
        conn.send('info')
        conn.send('now_playing')
      end

      def on_quit
        application.logger.warn { "#{self.class}#quit" }
        application.quit
      end
    end
  end
end
