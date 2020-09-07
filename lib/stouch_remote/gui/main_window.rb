require 'gtk3'

module STouchRemote
  class Gui
    class MainWindow < Gtk::ApplicationWindow
      type_register

      class <<self
        def init
          set_template data: File.read(File.join(__dir__, 'main_window.ui'))

          bind_template_child 'quit_menuitem'
          bind_template_child 'about_menuitem'
          bind_template_child 'device_name_label'
          bind_template_child 'progressbar'
        end
      end

      def initialize(application)
        super application: application

        about_menuitem.signal_connect 'activate' do
          Gui::AboutDialog.new.show_all
        end
        quit_menuitem.signal_connect 'activate' do
          on_quit
        end

        signal_connect 'show' do
          on_show
        end
      end

      def on_quit
        application.logger.warn { "#{self.class}#quit" }
        application.quit
      end

      def on_show
        application.logger.info { 'on_show' }
        start_progressbar('Connecting...')
        application.conn.start
        progressbar_pulse
        application.conn.send('info')
        progressbar_pulse
        application.conn.logger.info { 'on_show end' }
      end

      private

      def start_progressbar(text)
        progressbar.text = text
        progressbar.pulse
      end

      def progressbar_pulse
        progressbar.pulse
      end
    end
  end
end
