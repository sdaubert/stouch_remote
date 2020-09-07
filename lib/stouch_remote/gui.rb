# frozen_string_literal: true

require 'gtk3'

module STouchRemote
  class Gui < Gtk::Application
    attr_reader :app
    attr_reader :conn
    attr_reader :logger
    attr_reader :main_window

    def initialize(conn, logger)
      super 'org.gtk.stouch-remote'

      conn.set_handler Gui::ConnHandler
      conn.handler.app = self
      @conn = conn
      @logger = logger
      @main_window = nil

      signal_connect 'startup' do |application|
        conn.logger.info { 'App startup' }
        @main_window = Gui::MainWindow.new(application)
        @main_window.present
      end

      signal_connect 'activate' do
        conn.logger.info { 'App activation' }
        @main_window.show_all
      end
    end

    def set_device(str)
      @builder['label_device_name'].set_markup(str)
    end
  end
end

require_relative 'gui/conn_handler'
require_relative 'gui/main_window'
