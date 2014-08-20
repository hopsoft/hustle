require "drb"
require "forwardable"
require_relative "hustle/version"
require_relative "hustle/runner"
require_relative "hustle/hustler"

module Hustle
  class << self
    extend Forwardable
    def_delegators :"Hustle::Hustler.instance", :go, :wait
  end
end

Signal.trap(0) do
  Hustle.wait
  DRb.stop_service
end
