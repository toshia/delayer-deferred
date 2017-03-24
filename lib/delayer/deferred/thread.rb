# -*- coding: utf-8 -*-
require "delayer"
require "delayer/deferred/deferredable/awaitable"

class Thread
  include ::Delayer::Deferred::Deferredable::Awaitable

  def self.delayer
    Delayer
  end

  # このDeferredが成功した場合の処理を追加する。
  # 新しいDeferredのインスタンスを返す
  # TODO: procが空のとき例外を発生させる
  def next(&proc)
    add_child(Delayer::Deferred::Chain::Next.new(&proc))
  end
  alias deferred next

  # このDeferredが失敗した場合の処理を追加する。
  # 新しいDeferredのインスタンスを返す
  # TODO: procが空のとき例外を発生させる
  def trap(&proc)
    add_child(Delayer::Deferred::Chain::Trap.new(&proc))
  end
  alias error trap

  def add_child(chainable)
    __gen_promise.add_child(chainable)
  end

  private

  def __gen_promise
    promise = self.class.delayer.Promise.new(true)
    Thread.new(self) do |tt|
      __promise_callback(tt, promise)
    end
    promise
  end

  def __promise_callback(tt, promise)
    begin
      promise.call(tt.value)
    rescue Exception => err
      promise.fail(err)
    end
  end

end
