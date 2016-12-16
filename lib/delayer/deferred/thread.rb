# -*- coding: utf-8 -*-
require "delayer"
require "delayer/deferred/deferredable"

class Thread
  include ::Delayer::Deferred::Deferredable

  def self.delayer
    Delayer
  end

  def next(&block)
    __promise__.next(&block)
  end

  def trap(&block)
    __promise__.trap(&block)
  end

  alias :deferredable_cancel :cancel
  def cancel
    deferredable_cancel
    kill end

  private

  def __promise__(&block)
    promise = delayer.Deferred.new(true)
    Thread.new do
      begin
        promise.call(self.value)
      rescue Exception => err
        promise.fail(err)
      end
    end
    promise
  end
end
