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
  def assert_equal_deferred(expect, message = nil, &defer)
    result = exception = nil
    eval_all_events do
      defer.call.next { |r|
        result = r
      }.trap do |exc|
        exception = exc
      end
    end
    refute exception, 'except success, but failed.'
    assert_equal expect, result, message
  end

  def assert_fail_deferred(comparator, message = nil, &defer)
    result = exception = nil
    eval_all_events do
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
