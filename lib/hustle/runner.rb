require "sourcify"

module Hustle
  class Runner
    attr_reader :uri, :pid, :value
    attr_accessor :callback_thread

    # methods to be run on the local instance

    def initialize(uri)
      @uri = uri
    end

    def remote_instance
      DRbObject.new_with_uri(uri)
    end

    def remote_instance_started?
      !pid.nil?
    end

    def remote_instance_ready?
      begin
        !remote_instance.uri.nil?
      rescue DRb::DRbConnError
        false
      end
    end

    def start_remote_instance
      return if remote_instance_started?
      @pid = fork do
        DRb.start_service uri, self
        DRb.thread.join
      end
      Process.detach pid
      pid
    end

    def stop_remote_instance
      remote_instance.stop
    end

    def run_remote(&block)
      sleep 0 while !remote_instance_ready?
      source = block.to_source(strip_enclosure: true)
      remote_instance.run source
    end

    # methods to be run on the remote instance

    def stop
      DRb.stop_service
    end

    def run(source)
      begin
        eval source
      rescue Exception => e
        e
      end
    end

  end
end
