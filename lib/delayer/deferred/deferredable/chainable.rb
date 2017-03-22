# -*- coding: utf-8 -*-
require "delayer/deferred/deferredable/node_sequence"

module Delayer::Deferred::Deferredable
  module Chainable
    include NodeSequence

    attr_reader :child

    # このDeferredが成功した場合の処理を追加する。
    # 新しいDeferredのインスタンスを返す
    def next(&proc)
      change_sequence(:get_child)
      @child = Delayer::Deferred::Next.new(&proc)
    end
    alias deferred next

    # このDeferredが失敗した場合の処理を追加する。
    # 新しいDeferredのインスタンスを返す
    def trap(&proc)
      change_sequence(:get_child)
      @child = Delayer::Deferred::Trap.new(&proc)
    end
    alias error trap

    def has_child?
      child ? true : false
    end
  end
end
