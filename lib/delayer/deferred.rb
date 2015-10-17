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
    extend Delayer::Deferred::Tools

    class << self
      #真ならデバッグ情報を集める
      attr_accessor :debug

      def new(*rest, &proc)
        Delayer::Deferred::Deferred.new(*rest, &proc) end
    end
  end

  module Extend
    def Deferred
      @deferred ||= begin
                      the_delayer = self
                      Class.new(::Delayer::Deferred::Deferred) {
                        define_singleton_method(:delayer) {
                          the_delayer } } end
    end
  end
end

Delayer::Deferred.debug = false
