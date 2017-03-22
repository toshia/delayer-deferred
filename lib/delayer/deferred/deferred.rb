# -*- coding: utf-8 -*-
require "delayer/deferred/promise"
require "delayer/deferred/chain"
require "delayer/deferred/deferredable"
require "delayer/deferred/tools"
require "delayer/deferred/worker"
require "delayer/deferred/version"

module Delayer::Deferred
  module Deferred
    extend Delayer::Deferred::Tools

    def self.Thread
      @thread_class ||= gen_thread_class end

    def self.gen_thread_class
      the_delayer = delayer
      Class.new(Thread) do
        define_singleton_method(:delayer) do
          the_delayer end end end

    def self.delayer
      ::Delayer end

    def self.Promise
      @promise ||= begin
                     the_delayer = delayer
                     Class.new(::Delayer::Deferred::Promise) {
                       define_singleton_method(:delayer) {
                         the_delayer } } end
    end

    def self.new(stop=false, &block)
      result = promise = self.Promise.new
      result = self.Promise.new.next(&block) if block_given?
      promise.call(true) unless stop
      result
    end
  end
end
