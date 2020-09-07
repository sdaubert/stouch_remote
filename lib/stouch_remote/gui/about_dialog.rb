require 'gtk3'

module STouchRemote
  class Gui
    class AboutDialog < Gtk::AboutDialog
      type_register

      class <<self
        def init
          set_template data: File.read(File.join(__dir__, 'about_dialog.ui'))
        end
      end

      def initialize
        super
        #signal_connect 'show' do |dialog|
        #  p dialog
        #  dialog.version = VERSION
        #end
        self.version = VERSION
      end
    end
  end
end
