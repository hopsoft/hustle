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
      @drb ||= DRb.start_service
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
      sleep 0 while !runner.remote_instance_ready?
      synchronize do
        active_runners[runner.pid] = runner
      end
      runner.run_remote(&block)
      finish runner, callback
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

    def finish(runner, callback)
      runner.callback_thread = Thread.new do
        sleep 0.01 while !runner.remote_instance_finished?
        value = runner.remote_value
        runner.stop_remote_instance
        stop_drb
        synchronize do
          active_runners.delete(runner.pid)
        end
        callback.call value
      end
    end

  end

end

Signal.trap(0) do
  Hustle.wait
  DRb.stop_service
end
