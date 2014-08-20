require_relative "hustle/version"
require_relative "hustle/runner"
require "os"
require "socket"
require "drb"
require "thread"
require "singleton"
require "forwardable"

module Hustle
  class << self
    extend Forwardable
    def_delegators :"Hustle::Hustler.instance", :go
  end

  class Hustler
    include Singleton

    def mutex
      @mutex ||= Mutex.new
    end

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
      mutex.synchronize do
        if active_runners.empty?
          DRb.stop_service
          @drb = nil
        end
      end
    end

    def go(callback: -> (val) {}, &block)
      start_drb
      wait while active_runners.size >= cores.size
      uri = "druby://127.0.0.1:#{random_port}"
      runner = Runner.new(uri)
      runner.start_remote_instance
      wait while !runner.remote_instance_ready?
      runner.run_remote(&block)
      finish runner, callback
    end

    def join
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
        wait while !runner.remote_instance_finished?
        value = runner.remote_value
        runner.stop_remote_instance
        stop_drb
        mutex.synchronize do
          active_runners.delete(runner.pid)
        end
        callback.call value
      end

      mutex.synchronize do
        active_runners[runner.pid] = runner
      end
    end

    def wait
      sleep 0.0001
    end

  end

end

Signal.trap(0) do
  Hustle::Hustler.instance.join
  DRb.stop_service
end
