# -*- coding: utf-8 -*-
require "delayer"
require "delayer/deferred/deferredable/awaitable"

class Thread
  include ::Delayer::Deferred::Deferredable::Awaitable

  def self.delayer
    Delayer
  end

  # このDeferredが成功した場合の処理を追加する。
  # 新しいDeferredのインスタンスを返す。
  # このメソッドはスレッドセーフです。
  # TODO: procが空のとき例外を発生させる
  def next(name: caller_locations(1,1).first.to_s, &proc)
    add_child(Delayer::Deferred::Chain::Next.new(&proc), name: name)
  end
  alias deferred next

  # このDeferredが失敗した場合の処理を追加する。
  # 新しいDeferredのインスタンスを返す。
  # このメソッドはスレッドセーフです。
  # TODO: procが空のとき例外を発生させる
  def trap(name: caller_locations(1,1).first.to_s, &proc)
    add_child(Delayer::Deferred::Chain::Trap.new(&proc), name: name)
  end
  alias error trap

  def add_child(chainable, name: caller_locations(1,1).first.to_s)
    __gen_promise(name).add_child(chainable)
  end

  private

  def __gen_promise(name)
    promise = self.class.delayer.Promise.new(true, name: name)
    Thread.new(self) do |tt|
      __promise_callback(tt, promise)
    end
    promise
  end

  def __promise_callback(tt, promise)
    begin
      result = tt.value
      self.class.delayer.new do
        promise.call(result)
      end
    rescue Exception => err
      self.class.delayer.new do
        promise.fail(err)
      end
    end
  end

end
