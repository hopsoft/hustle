require_relative "hustle/version"
require_relative "hustle/runner"
require "os"
require "socket"
require "drb"

module Hustle

  class << self

    def cores
      @cores ||= OS.cpu_count
    end

    def runners
      @runners ||= {}
    end

    def start_drb
      @drb ||= DRb.start_service
    end

    def stop_drb
      if runners.empty?
        DRb.stop_service
        @drb = nil
      end
    end

    def hustle(&block)
      start_drb
      sleep 0 while runners.size >= cores.size
      uri = "druby://127.0.0.1:#{random_port}"
      runner = Runner.new(uri)
      runners[uri] = runner
      runner.start_remote_instance
      sleep 0 while !runner.remote_instance_ready?
      value = runner.run_remote(&block)
      runner.stop_remote_instance
      runners.delete uri
      stop_drb
      value
    end

    private

    def random_port
     socket = Socket.new(:INET, :STREAM, 0)
     socket.bind(Addrinfo.tcp("127.0.0.1", 0))
     port = socket.local_address.ip_port
     socket.close
     port
    end
  end

end
