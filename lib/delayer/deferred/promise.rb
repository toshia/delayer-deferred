# -*- coding: utf-8 -*-
require "delayer/deferred/tools"
require "delayer/deferred/deferredable/trigger"

module Delayer::Deferred
  class Promise
    extend Delayer::Deferred::Tools
    include Deferredable::Trigger

    class << self
      def new(stop=false, name: caller_locations(1,1).first.to_s,  &block)
        result = promise = super(name: name)
        result = promise.next(&block) if block_given?
        promise.call(true) unless stop
        result
      end

      def Thread
        @thread_class ||= gen_thread_class end

      def Promise
        self
      end

      def delayer
        ::Delayer
      end

      def to_s
        "#{self.delayer}.Promise"
      end

      private

      def gen_thread_class
        the_delayer = delayer
        Class.new(Thread) do
          define_singleton_method(:delayer) do
            the_delayer
          end
        end
      end
    end

    def initialize(name:)
      super()
      @name = name
    end

    def activate(response)
      change_sequence(:activate)
      change_sequence(:complete)
      response
    end

    def inspect
      "#<#{self.class} seq:#{sequence.name}>"
    end

    def ancestor
      self
    end

    def parent=(chainable)
      fail Error, "#{self.class} can't has parent."
    end

    private

    def graph_shape
      'egg'.freeze
    end

    def node_name
      @name.to_s
    end
  end
end
