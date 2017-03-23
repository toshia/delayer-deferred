# -*- coding: utf-8 -*-
require "delayer/deferred/chain"

module Delayer::Deferred
  class Await < Chain
    def initialize(worker:, deferred:)
      super()
      @worker, @awaiting_deferred = worker, deferred
    end

    def activate(response)
      change_sequence(:activate)
      @worker.give_response(response, @awaiting_deferred)
    # TODO: 即座にspoilさせてよさそう
    ensure
      change_sequence(:complete)
    end

  end
end