# -*- coding: utf-8 -*-
require "delayer/deferred/tools"
require "delayer/deferred/deferredable/trigger"

module Delayer::Deferred
  class Promise
    include Deferredable::Trigger

    def self.new(stop=false, &block)
      result = promise = super()
      result = super().next(&block) if block_given?
      promise.call(true) unless stop
      result
    end

    class << self
      def method_missing(*rest, &block)
        Delayer::Deferred::Deferred.__send__(*rest, &block)
      end
    end

    def activate(response)
      change_sequence(:activate)
      change_sequence(:complete)
      response
    end

    def inspect
      "#<#{self.class.delayer}.Promise seq:#{sequence.name}>"
    end
  end
end
