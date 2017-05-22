# -*- coding: utf-8 -*-
require "delayer/deferred/chain/base"

module Delayer::Deferred::Chain
  class Await < Base
    def initialize(worker:, deferred:)
      super()
      @worker, @awaiting_deferred = worker, deferred
      deferred.add_awaited(self)
    end

    def activate(response)
      change_sequence(:activate)
      @worker.give_response(response, @awaiting_deferred)
    # TODO: 即座にspoilさせてよさそう
    ensure
      change_sequence(:complete)
    end

    def graph_child(output:)
      output << graph_mynode
      if has_child?
        @child.graph_child(output: output)
        @awaiting_deferred.graph_child(output: output)
        output << "#{__id__} -> #{@child.__id__}"
      end
      nil
    end

    def node_name
      "Await"
    end

    def graph_shape
      'circle'.freeze
    end

    def graph_mynode
      label = "#{node_name}\n(#{sequence.name})"
      "#{__id__} [shape=#{graph_shape},label=#{label.inspect}]"
    end
  end
end
