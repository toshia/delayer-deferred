# -*- coding: utf-8 -*-
require "delayer/deferred/chain"

module Delayer::Deferred
  class Next < Chain
    def evaluate?(response)
      response.ok?
    end

    private

    def graph_shape
      'box'.freeze
    end
  end
end
