# frozen_string_literal: true

require 'gtk3'

module STouchRemote
  class Gui < Gtk::Application
    attr_reader :app
    attr_reader :conn
    attr_reader :logger
    attr_reader :main_window
    attr_reader :connected

    def initialize(conn, logger)
      super 'org.gtk.stouch-remote'

      conn.set_handler Gui::ConnHandler
      conn.handler.app = self
      @conn = conn
      @logger = logger
      @main_window = nil
      @connected = false

      signal_connect 'startup' do |application|
        conn.logger.info { 'App startup' }
        @main_window = Gui::MainWindow.new(application, conn)
        @main_window.present
        @main_window.show_all
      end

      signal_connect 'activate' do
        logger.info { 'App activation' }
        GLib::Timeout.add(100) do
          main_window.on_connect
          false
        end
      end
    end

    def set_device(str)
      @builder['label_device_name'].set_markup(str)
    end

    def connected=(val)
      main_window.main_grid.sensitive = val
      @connected = val
    end
  end
end

require_relative 'gui/conn_handler'
require_relative 'gui/main_window'
require_relative 'gui/about_dialog'
