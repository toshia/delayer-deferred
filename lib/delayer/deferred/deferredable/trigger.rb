# -*- coding: utf-8 -*-
require "delayer/deferred/deferredable/chainable"
require "delayer/deferred/deferredable/node_sequence"
require "delayer/deferred/response"

module Delayer::Deferred::Deferredable
=begin rdoc
Promiseなど、親を持たず、自身がWorkerを作成できるもの。
=end
  module Trigger
    include NodeSequence
    include Chainable

    # Deferredを直ちに実行する。
    # このメソッドはスレッドセーフです。
    def call(value = nil)
      execute(Delayer::Deferred::Response::Ok.new(value))
    end

    # Deferredを直ちに失敗させる。
    # このメソッドはスレッドセーフです。
    def fail(exception = nil)
      execute(Delayer::Deferred::Response::Ng.new(exception))
    end

    private

    def execute(value)
      worker = Delayer::Deferred::Worker.new(delayer: self.class.delayer,
                                             initial: value)
      worker.push(self)
    end
  end
end
