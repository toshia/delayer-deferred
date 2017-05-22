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

      def method_missing(*rest, &block)
        Delayer::Deferred::Deferred.__send__(*rest, &block)
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
