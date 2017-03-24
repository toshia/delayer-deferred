# -*- coding: utf-8 -*-
require "delayer/deferred/chain/base"

module Delayer::Deferred::Chain
  class Next < Base
    def evaluate?(response)
      response.ok?
    end

    private

    def graph_shape
      'box'.freeze
    end
  end
end
