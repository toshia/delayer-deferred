# -*- coding: utf-8 -*-
require "delayer/deferred/deferredable/node_sequence"
require "delayer/deferred/deferredable/chainable"

module Delayer::Deferred
  class Chain
    include Deferredable::NodeSequence
    include Deferredable::Chainable

    def initialize(&proc)
      fail Error, "Delayer::Deferred::Chain can't create instance." if self.class == Delayer::Deferred::Chain
      @proc = proc
    end

    def activate(response)
      change_sequence(:activate)
      if evaluate?(response)
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

require "delayer/deferred/chain/next"
require "delayer/deferred/chain/trap"
