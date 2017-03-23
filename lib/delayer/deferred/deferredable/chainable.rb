# -*- coding: utf-8 -*-
require "delayer/deferred/deferredable/node_sequence"
require "delayer/deferred/deferredable/awaitable"

module Delayer::Deferred::Deferredable
  module Chainable
    include NodeSequence
    include Awaitable

    attr_reader :child

    # このDeferredが成功した場合の処理を追加する。
    # 新しいDeferredのインスタンスを返す
    # TODO: procが空のとき例外を発生させる
    def next(&proc)
      add_child(Delayer::Deferred::Next.new(&proc))
    end
    alias deferred next

    # このDeferredが失敗した場合の処理を追加する。
    # 新しいDeferredのインスタンスを返す
    # TODO: procが空のとき例外を発生させる
    def trap(&proc)
      add_child(Delayer::Deferred::Trap.new(&proc))
    end
    alias error trap

    def has_child?
      child ? true : false
    end

    # 子を追加する。
    # _Delayer::Deferred::Chainable_ を直接指定できる。通常外部から呼ぶときは _next_ か _trap_ メソッドを使うこと。
    # ==== Args
    # [chainable] 子となるDeferred
    # ==== Return
    # 必ず _chainable_ を返す
    # ==== Raise
    # [Delayer::Deferred::SequenceError]
    #   既に子が存在している場合
    def add_child(chainable)
      change_sequence(:get_child) do
        @child = chainable
      end
    end

    # 子が追加された時に一度だけコールバックするオブジェクトを登録する。
    # observerと言っているが、実際には _Delayer::Deferred::Worker_ を渡して利用している。
    # ==== Args
    # [observer] pushメソッドを備えているもの。引数に _@child_ の値が渡される
    # ==== Return
    # self
    def add_child_observer(observer)
      change_sequence(:gaze) do
        @child_observer = observer
      end
      self
    end

    # activateメソッドを呼ぶDelayerジョブを登録する寸前に呼ばれる。
    def reserve_activate
      change_sequence(:reserve)
    end

    private

    def call_child_observer
      if has_child? and defined?(@child_observer)
        change_sequence(:called)
        @child_observer.push(@child)
      end
    end

    def on_sequence_changed(old_seq, flow, new_seq)
      case new_seq
      when NodeSequence::BURST_OUT
        call_child_observer
      end
    end
  end
end
