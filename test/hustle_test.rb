require "micro_test"
require "pry"
require_relative "../lib/hustle"

class HustleTest < MicroTest::Test

  test "multiple processes spawned" do
    4.times do
      Hustle.go { sleep 0.1 }
    end

    assert Hustle::Hustler.instance.active_runners.size == 4
    Hustle.wait
  end

  test "mutate state in primary process" do
    data = { foo: nil, bar: nil }

    asserts = -> (value) do
      assert data[:foo] == 1
      assert data[:bar] == 2
    end

    Hustle.go callback: asserts do
      data[:foo] = 1
      data[:bar] = 2
    end
  end

  test "callback value" do
    asserts = -> (value) do
      assert Process.pid != value
    end

    Hustle.go(callback: asserts) do
      Process.pid
    end
  end

  test "error in block" do
    error_message = "Error in the block!"

    asserts = -> (value) do
      assert value.is_a?(StandardError)
      assert value.message == error_message
    end

    Hustle.go(callback: asserts) do
      raise error_message
    end
  end

end

