# -*- coding: utf-8 -*-

# -*- coding: utf-8 -*-

module Delayer::Deferred::Request
  class Base
    attr_reader :value
    def initialize(value)
      @value = value
    end

    # これを返したFiberが次のWorkerを要求しているなら真を返す
    def wait_next_worker?
      false
    end

    # 真なら、以降の子を実行せず、 _value_ の子に置き換える。
    def graft?
      true
    end

    # 真なら、Fiberがこれ以上値を要求せず、Workerを終了する。
    def exit?
      false
    end
  end

=begin rdoc
Fiberが次のWorkerを要求している時に返す値。
新たなインスタンスは作らず、 _NEXT_WORKER_ にあるインスタンスを使うこと。
=end
  class NextWorker < Base
    def wait_next_worker?
      true
    end

    def accept_request(worker:, deferred:)
      if deferred.has_child?
        worker.push(deferred.child)
      else
        puts "NextWorker: #{deferred.inspect} dont have child"
        # TODO: childが入ったら続行
      end
    end
  end

=begin rdoc
Deferredの結果がDeferredだった時に、別のWorkerに子を譲るためのリクエスト。
_value_ には、移譲先のDeferredが入っている。
=end
  class Graft < Base
    def graft?
      true
    end

    def exit?
      true
    end

    def accept_request(worker:, deferred:)
      if deferred.has_child?
        value.add_child(deferred.child)
      else
        puts "Graft: #{deferred.inspect} dont have child"
        # TODO: childが入ったら続行
      end
    end
  end

  NEXT_WORKER = NextWorker.new(nil)
end
