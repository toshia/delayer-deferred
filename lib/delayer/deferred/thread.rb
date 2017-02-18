# -*- coding: utf-8 -*-
require "delayer"
require "delayer/deferred/deferredable"

class Thread
  include ::Delayer::Deferred::Deferredable

  def self.delayer
    Delayer
  end

  def next(*rest, &block)
    __gen_promise.next(*rest, &block)
  end

  def trap(*rest, &block)
    __gen_promise.trap(*rest, &block)
  end

  private

  def __gen_promise
    promise = delayer.Deferred.new(true)
    Thread.new(self) do |tt|
      __promise_callback(tt, promise)
    end
    promise
  end

  def __promise_callback(tt, promise)
    failed = catch(:__deferredable_fail) do
      begin
        promise.call(tt.value)
      rescue Exception => err
        promise.fail(err)
      end
      return
    end
    promise.fail(failed)
  end

end
