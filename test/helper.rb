require 'bundler/setup'

require 'securerandom'
require 'set'
require 'timeout'
require_relative 'testutils'

require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

require 'delayer/deferred'
require 'minitest/autorun'
