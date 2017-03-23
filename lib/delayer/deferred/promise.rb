# -*- coding: utf-8 -*-
require "delayer/deferred/tools"
require "delayer/deferred/deferredable/trigger"

module Delayer::Deferred
  class Promise
    extend Delayer::Deferred::Tools
    include Deferredable::Trigger

    class << self
      def new(stop=false, &block)
        result = promise = super()
        result = super().next(&block) if block_given?
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

    def activate(response)
      change_sequence(:activate)
      change_sequence(:complete)
      response
    end

    def inspect
      "#<#{self.class.delayer}.Promise seq:#{sequence.name}>"
    end
  end
end
