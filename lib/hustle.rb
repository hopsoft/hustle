require_relative "hustle/version"
require_relative "hustle/runner"
require "os"
require "socket"
require "drb"
require "thread"
require "singleton"
require "forwardable"
require "monitor"

module Hustle
  class << self
    extend Forwardable
    def_delegators :"Hustle::Hustler.instance", :go, :wait
  end

  class Hustler
    include Singleton
    include MonitorMixin

    def cores
      @cores ||= OS.cpu_count
    end

    def active_runners
      @active_runners ||= {}
    end

    def start_drb
      @drb ||= begin
        DRb.start_service
        sleep 0 while server.is_a?(DRb::DRbServerNotFound)
      end
    end

    def stop_drb
      synchronize do
        if active_runners.empty?
          DRb.stop_service
          @drb = nil
        end
      end
    end

    def go(callback: -> (val) {}, &block)
      start_drb
      sleep 0 while active_runners.size >= cores.size
      uri = "druby://127.0.0.1:#{random_port}"
      runner = Runner.new(uri)
      runner.start_remote_instance
      synchronize do
        active_runners[runner.pid] = runner
      end
      finish runner, callback, &block
    end

    def wait
      active_runners.each do |_, runner|
        runner.callback_thread.join
      end
    end

    private

    def random_port
     socket = Socket.new(:INET, :STREAM, 0)
     socket.bind(Addrinfo.tcp("127.0.0.1", 0))
     port = socket.local_address.ip_port
     socket.close
     port
    end

    def finish(runner, callback, &block)
      runner.callback_thread = Thread.new do
        value = runner.run_remote(&block)
        runner.stop_remote_instance
        synchronize do
          active_runners.delete(runner.pid)
        end
        stop_drb
        callback.call value
      end
    end

    def server
      begin
        DRb.current_server
      rescue DRb::DRbServerNotFound => e
        e
      end
    end

  end

end

Signal.trap(0) do
  Hustle.wait
  DRb.stop_service
end
