# -*- coding: utf-8 -*-

# -*- coding: utf-8 -*-

module Delayer::Deferred::Request
  class Base
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end

=begin rdoc
Fiberが次のWorkerを要求している時に返す値。
新たなインスタンスは作らず、 _NEXT_WORKER_ にあるインスタンスを使うこと。
=end
  class NextWorker < Base
    def accept_request(worker:, deferred:)
      if deferred.has_child?
        worker.push(deferred.child)
      else
        deferred.add_child_observer(worker)
      end
    end
  end

=begin rdoc
Deferredの結果がDeferredだった時に、別のWorkerに子を譲るためのリクエスト。
_value_ には、移譲先のDeferredが入っている。
=end
  class Graft < Base
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
