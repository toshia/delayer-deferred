# -*- coding: utf-8 -*-
require "delayer/deferred/request"
require "delayer/deferred/response"

module Delayer::Deferred
=begin rdoc
Deferredを実行するためのWorker。Deferredチェインを実行するFiberを
管理する。

== pushに渡すオブジェクトについて
Worker#push に渡す引数は、activateメソッドを実装している必要がある。

=== activate(response)
==== Args
response :: Delayer::Deferred::Response::Base Deferredに渡す値
==== Returns
[Delayer::Deferred::Response::Base]
  これを返すと、値の自動変換が行われないため、意図的に失敗させたり、Deferredを次のブロックに伝搬させることができる。
[Delayer::Deferred::Chainable]
  戻り値のDeferredが終わるまでWorkerの処理を停止する。
  再開された時、結果は戻り値のDeferredの結果に置き換えられる。
[else]
  _Delayer::Deferred::Response::Ok.new_ の引数に渡され、その結果が利用される
=end
  class Worker
    def initialize(delayer:, initial:)
      @delayer, @initial = delayer, initial
    end

    def push(deferred)
      @delayer.new do
        fiber.resume(deferred).accept_request(worker: self,
                                              deferred: deferred)
      end
    end

    private

    def fiber
      @fiber ||= Fiber.new{|response|
        loop do
          response = wait_and_activate(response)
          case response.value
          when Deferredable::Chainable
            Fiber.yield(Request::Graft.new(response.value))
            break
          end
        end
      }.tap{|f| f.resume(@initial); @initial = nil }
    end

    def wait_and_activate(argument)
      response = catch(:success) do
        failed = catch(:__deferredable_fail) do
          begin
            throw :success, Fiber.yield(Request::NEXT_WORKER).activate(argument)
          rescue Exception => err
            throw :__deferredable_fail, err
          end
        end
        Response::Ng.new(failed)
      end
      if response.is_a?(Response::Base)
        response
      else
        Response::Ok.new(response)
      end
    end
  end
end
