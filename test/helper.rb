require 'bundler/setup'

require 'securerandom'
require 'set'
require 'timeout'
require_relative 'testutils'

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest'

module Minitest::Assertions
  def assert_equal_deferred(expect, message = nil, delayer: Delayer.default, &defer)
    raise 'Delayer not set!' unless delayer
    result = exception = nil
    eval_all_events(delayer) do
      defer.call.next { |r|
        result = r
      }.trap do |exc|
        exception = exc
      end
    end
    assert_equal nil, exception&.full_message(highlight: false)#, 'except success, but failed.'
    assert_equal expect, result, message
  end

  def assert_fail_deferred(comparator, message = nil, delayer: Delayer.default, &defer)
    result = exception = nil
    eval_all_events(delayer) do
      defer.call.next { |r|
        result = r
      }.trap do |exc|
        exception = exc
      end
    end
    refute expect, 'except fail, but succeed.'
    assert comparator === exception, message
  end
end

require 'delayer/deferred'
require 'minitest/autorun'
