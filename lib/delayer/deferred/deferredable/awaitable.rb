# -*- coding: utf-8 -*-

module Delayer::Deferred::Deferredable
  module Awaitable

    # _self_ が終了して結果が出るまで呼び出し側のDeferredを停止し、 _self_ の結果を返す。
    # 呼び出し側はDeferredブロック内でなければならないが、 _Deferred#next_ を使わずに
    # 直接戻り値を得ることが出来る。
    # _self_ が失敗した場合は、呼び出し側のDeferredの直近の _trap_ ブロックが呼ばれる。
    def +@
      response = Fiber.yield(Delayer::Deferred::Request::Await.new(self))
      if response.ok?
        response.value
      else
        Delayer::Deferred.fail(response.value)
      end
    end

    def enter_await
      change_sequence(:await)
    end

    def exit_await
      change_sequence(:resume)
    end
  end
end
