require "method_source"

module Hustle
  class Runner
    attr_reader :uri, :pid, :context
    attr_accessor :callback_thread

    # methods to be run on the local instance

    def initialize(uri, context: {})
      @uri = uri
      @context = context
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
      code_string = proc_to_string(block)
      remote_instance.run code_string
    end

    def proc_to_string(proc)
      code = proc.source
      start = code.index(/(?<=\{| do)/)
      finish = code.rindex(/\}|end/) - 1
      code[start..finish].strip
    end

    # methods to be run on the remote instance

    def stop
      DRb.stop_service
    end

    def run(code_string)
      begin
        eval code_string, binding
      rescue Exception => e
        e
      end
    end

  end
end
