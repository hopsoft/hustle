module Hustle

  class Runner
    attr_reader :uri, :pid

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
      remote_instance.run(&block)
    end

    # methods to be run on the remote instance

    def stop
      DRb.stop_service
    end

    def run(&block)
      yield
    end
  end

end
