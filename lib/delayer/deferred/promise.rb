# -*- coding: utf-8 -*-
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

    def activate(response)
      change_sequence(:activate)
      response
    ensure
      change_sequence(:complete)
    end

    def inspect
      "#<#{self.class.delayer}.Promise seq:#{sequence.name}>"
    end
  end
end
