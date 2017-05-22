# -*- coding: utf-8 -*-
require "delayer/deferred/deferredable/chainable"
require "delayer/deferred/deferredable/node_sequence"

module Delayer::Deferred::Chain
  class Base
    include Delayer::Deferred::Deferredable::NodeSequence
    include Delayer::Deferred::Deferredable::Chainable

    def initialize(&proc)
      fail Error, "Delayer::Deferred::Chain can't create instance." if self.class == Delayer::Deferred::Chain::Base
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
      "#<#{self.class} seq:#{sequence.name} child:#{has_child?}>"
    end

    def node_name
      @proc.source_location.join(':'.freeze)
    end
  end
end

