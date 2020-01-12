# coding: utf-8
require "delayer"
require "delayer/deferred/deferred"
require "delayer/deferred/deferredable"
require "delayer/deferred/enumerable"
require "delayer/deferred/enumerator"
require "delayer/deferred/thread"
require "delayer/deferred/tools"
require "delayer/deferred/version"

module Delayer
  module Deferred
    class << self
      #真ならデバッグ情報を集める
      attr_accessor :debug

      def new(*rest, name: caller_locations(1,1).first.to_s, &block)
        super(*rest, name: name, &block)
      end

      def method_missing(*rest, **kwrest, &block)
        if kwrest.empty?
          Delayer::Deferred::Promise.__send__(*rest, &block)
        else
          Delayer::Deferred::Promise.__send__(*rest, **kwrest, &block)
        end
      end

      def respond_to_missing?(symbol, include_private)
        Delayer::Deferred::Promise.respond_to?(symbol, include_private)
      end
    end
  end

  module Extend
    def Promise
      @promise ||= begin
                     the_delayer = self
                     Class.new(::Delayer::Deferred::Promise) {
                       define_singleton_method(:delayer) {
                         the_delayer } } end
    end
    alias :Deferred :Promise
    #deprecate :Deferred, "Promise", 2018, 03
  end
end

Delayer::Deferred.debug = false
