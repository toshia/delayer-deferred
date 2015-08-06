# -*- coding: utf-8 -*-
module Delayer::Deferred
  class Deferred
    include Deferredable

    def self.Thread
      @thread_class ||= gen_thread_class end

    def self.gen_thread_class
      the_delayer = delayer
      Class.new(Thread) do
        define_singleton_method(:delayer) do
          the_delayer end end end

    def self.delayer
       ::Delayer end

    def initialize(follow = nil)
      @follow = follow
      @backtrace = caller if ::Delayer::Deferred.debug end

    alias :deferredable_cancel :cancel
    def cancel
      deferredable_cancel
      @follow.cancel if @follow.is_a? Deferredable end
  end
end
