# -*- coding: utf-8 -*-
require "delayer/deferred/chain/base"

module Delayer::Deferred::Chain
  class Trap < Base
    def evaluate?(response)
      response.ng?
    end

    private

    def graph_shape
      'diamond'.freeze
    end
  end
end
