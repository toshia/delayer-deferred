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

    # _self_ が終了して結果が出るまで呼び出し側のDeferredを停止し、 _self_ の結果を返す。
    # 呼び出し側はDeferredブロック内でなければならないが、 _Deferred#next_ を使わずに
    # 直接戻り値を得ることが出来る。
    # _self_ が失敗した場合は、呼び出し側のDeferredの直近の _trap_ ブロックが呼ばれる。
    def +@
      interrupt = Fiber.yield(self)
      if interrupt.ok?
        interrupt.value
      else
        Delayer::Deferred.fail(interrupt.value)
      end
    end

    # この一連のDeferredをこれ以上実行しない
    # TODO:
    def cancel
      @callback = Callback.new(CallbackDefaultOK,
                               CallbackDefaultNG).freeze end

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
