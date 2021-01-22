# -*- coding: utf-8 -*-

require 'delayer/deferred/chain/base'

module Delayer::Deferred::Chain
  class RactorChain < Base
    def activate(response)
      deferred = ancestor.class.delayer.Deferred
      change_sequence(:activate)
      if evaluate?(response)
        deferred.Thread.new do
          Ractor.new(response.value, &@proc).take
        end
      else
        response
      end
    ensure
      change_sequence(:complete)
    end
  end

  class RactorChainNext < RactorChain
    def evaluate?(response)
      response.ok?
    end

    private

    def graph_shape
      'box'.freeze
    end
  end

  class RactorChainTrap < RactorChain
    def evaluate?(response)
      response.ng?
    end

    private

    def graph_shape
      'diamond'.freeze
    end
  end
end
