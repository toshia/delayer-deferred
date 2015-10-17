# -*- coding: utf-8 -*-
require "delayer/deferred/deferredable"
require "delayer/deferred/tools"
require "delayer/deferred/version"

module Delayer::Deferred
  class Deferred
    extend Delayer::Deferred::Tools
    include Deferredable

    def self.inherited(subclass)
      subclass.extend(::Delayer::Deferred)
    end

    def self.Thread
      @thread_class ||= gen_thread_class end

    def self.gen_thread_class
      the_delayer = delayer
      Class.new(Thread) do
        define_singleton_method(:delayer) do
          the_delayer end end end

    def self.delayer
       ::Delayer end

    def self.new(*args)
      deferred = super(*args)
      if block_given?
        deferred.next(&Proc.new)
      else
        deferred end
    end

    def initialize(follow = nil)
      super()
      @follow = follow
      @backtrace = caller if ::Delayer::Deferred.debug end

    alias :deferredable_cancel :cancel
    def cancel
      deferredable_cancel
      @follow.cancel if @follow.is_a? Deferredable end

    def inspect
      if ::Delayer::Deferred.debug
        sprintf("#<%s: %p %s follow:%p stat:%s value:%s>".freeze, self.class, object_id, @backtrace.find{|n|not n.include?("delayer/deferred".freeze)}, @follow ? @follow.object_id : 0, @next_call_stat.inspect, @next_call_value.inspect)
      else
        sprintf("#<%s: %p stat:%s value:%s>".freeze, self.class, object_id, @next_call_stat.inspect, @next_call_value.inspect)
      end
    end
  end
end
