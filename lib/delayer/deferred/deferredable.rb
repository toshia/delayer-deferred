# -*- coding: utf-8 -*-
require "delayer/deferred/version"

module Delayer::Deferred
  module Deferredable

  #   # second 秒待って次を実行する
  #   # ==== Args
  #   # [second] 待つ秒数(second)
  #   # ==== Return
  #   # Deferred
  #   def wait(second)
  #     self.next{ Thread.new{ sleep(second) } } end

  #   # TODO:
  #   def assigned?
  #     defined?(@next)
  #   end
  end
end

require "delayer/deferred/deferredable/awaitable"
require "delayer/deferred/deferredable/chainable"
require "delayer/deferred/deferredable/graph"
require "delayer/deferred/deferredable/node_sequence"
require "delayer/deferred/deferredable/trigger"
