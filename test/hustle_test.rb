require "micro_test"
require "pry"
require_relative "../lib/hustle"

class HustleTest < MicroTest::Test

  test "multiple processes spawned" do
    4.times do
      Hustle.go { sleep 1 }
    end

    assert Hustle::Hustler.instance.active_runners.size == 4
    Hustle.wait
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
    asserts = -> (value) do
      assert value.is_a?(ZeroDivisionError)
    end

    Hustle.go(callback: asserts) do
      1/0
    end
  end

  test "cpu intense work" do
    asserts = -> (value) do
      assert value == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765, 10946, 17711, 28657, 46368, 75025, 121393, 196418, 317811, 514229, 832040, 1346269, 2178309, 3524578, 5702887, 9227465, 14930352, 24157817]
    end

    Hustle.go callback: asserts do
      class Fibinocci
        def calc(n)
          n < 2 ? n : calc(n-1) + calc(n-2)
        end
      end
      38.times.map { |i| Fibinocci.new.calc(i) }
    end
  end

  test "context passing" do
    data = { a: 0, b: 1 }

    asserts = -> (value) do
      assert value.is_a?(Hash)
      assert value[:a] == 0
      assert value[:b] == 3
      assert data.object_id != value.object_id
    end

    Hustle.go context: data, callback: asserts do
      context[:b] = 3
      context
    end
  end

  test "execution order" do
    x = 1
    asserts = -> (value) do
      assert x == 1
      x = value
      assert x == 2
    end

    Hustle.go callback: asserts do
      sleep 0.1
      2
    end

    assert x == 1
    Hustle.wait
  end

end

