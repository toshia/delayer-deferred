# -*- coding: utf-8 -*-
require "delayer/deferred/deferredable"
require "delayer/deferred/deferredable/chainable"
require "delayer/deferred/deferredable/node_sequence"

module Delayer::Deferred::Deferredable
=begin rdoc
Promiseなど、親を持たず、自身がWorkerを作成できるもの。
=end
  module Trigger
    include NodeSequence
    include Chainable

    # Deferredを直ちに実行する
    def call(value = nil)
      execute(true, value)
    end

    # Deferredを直ちに失敗させる
    def fail(exception = nil)
      execute(false, exception)
    end

    private

    def execute(success, value)
      worker = Delayer::Deferred::Worker.new(delayer: self.class.delayer,
                                             initial: value)
      worker.push(self)
    end
  end
end
