# -*- coding: utf-8 -*-

module Enumerable
  # 遅延each。あとで実行されるし、あんまりループに時間がかかるようなら一旦ループを終了する
  def deach(delayer=Delayer, &proc)
    iteratee = to_a
    iteratee = dup if equal?(iteratee)
    Delayer::Deferred::Deferred.new do
      result = nil
      while not iteratee.empty?
        item = iteratee.shift
        proc.call(item)
        if delayer.expire?
          break result = iteratee.deach(&proc) end end
      result end
  end
end






