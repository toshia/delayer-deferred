# -*- coding: utf-8 -*-

require_relative 'helper'

describe(Enumerable) do
  include TestUtils

  before do
    @delayer = Delayer.generate_class
  end

  describe "deach" do
    it "iterate Array" do
      sum = 0
      eval_all_events(@delayer) do
        (1..10000).to_a.deach(@delayer) do |digit|
          sum += digit
        end
      end
      assert_equal 50005000, sum
    end

    it "iterate infinite Enumerator" do
      log = []
      finish = failure = nil
      @delayer = Delayer.generate_class(expire: 0.1)
      fib = Enumerator.new do |yielder|
        a = 1
        b = 1
        loop do
          c = a + b
          yielder << a
          a, b = b, c end end
      Timeout.timeout(1) {
        fib.deach(@delayer) {|digit|
          log << digit
        }.next{
          finish = true
        }.trap {|exception|
          failure = exception
        }
        @delayer.run
      }
      refute failure
      refute finish, "Enumerable#deach won't call next block"
      refute log.empty?, "Executed deach block"
      log_size = log.size
      sample_size = [156, log_size].min
      assert_equal fib.take(sample_size), log.take(sample_size), "deach block takes collect arguments"
      @delayer.run
      refute failure
      refute finish, "Enumerable#deach won't call next block"
      assert log.size > log_size, "Restart iteration if call Delayer#run (first #{log_size} iterations, second #{log.size})"
    end


  end
end
