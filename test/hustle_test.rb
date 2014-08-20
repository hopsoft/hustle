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
    Hustle.wait
  end

  test "callback value" do
    asserts = -> (value) do
      puts "#{Process.pid} != #{value}"
      assert Process.pid != value
    end

    Hustle.go(callback: asserts) do
      Process.pid
    end

    Hustle.wait
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

    Hustle.wait
  end

  test "cpu intense work" do
    asserts = -> (value) do
      puts value.inspect
      assert value == []
    end

    Hustle.go callback: asserts do
      class Fibinocci
        def calc(n)
          n < 2 ? n : calc(n-1) + calc(n-2)
        end
      end
      38.times.map { |i| Fibinocci.new.calc(i) }
    end

    Hustle.wait
  end

end

