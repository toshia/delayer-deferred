# -*- coding: utf-8 -*-
require "delayer/deferred/version"
require "delayer/deferred/deferredable/chainable"
require "delayer/deferred/deferredable/trigger"
require "delayer/deferred/deferredable/node_sequence"

# なんでもDeferred
module Delayer::Deferred
  module Deferredable
    include Chainable
    include NodeSequence

    # second 秒待って次を実行する
    # ==== Args
    # [second] 待つ秒数(second)
    # ==== Return
    # Deferred
    def wait(second)
      self.next{ Thread.new{ sleep(second) } } end

    # TODO:
    def assigned?
      defined?(@next)
    end
  end
end
