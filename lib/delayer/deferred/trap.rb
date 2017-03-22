# -*- coding: utf-8 -*-
require "delayer/deferred/deferredable/node_sequence"
require "delayer/deferred/deferredable/chainable"

module Delayer::Deferred
  class Trap
    include Deferredable::NodeSequence
    include Deferredable::Chainable

    def initialize(&proc)
      @proc = proc
    end

    def activate(response)
      change_sequence(:activate)
      if response.ng?
        @proc.(response.value)
      else
        response
      end
    ensure
      change_sequence(:complete)
    end

    def inspect
      "#<#{self.class} seq:#{sequence.name}>"
    end
  end
end
