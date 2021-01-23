# -*- coding: utf-8 -*-

require 'delayer/deferred/chain/base'

module Delayer::Deferred::Chain
  class RactorChain < Base
    def initialize(*args, &proc)
      super(&proc)
      @args = args.freeze
    end

    def activate(response)
      deferred = ancestor.class.delayer.Deferred
      change_sequence(:activate)
      if evaluate?(response)
        deferred.Thread.new do
          @args, args = nil, @args
          Ractor.new(response.value, *args, &@proc).take
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
