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
      deferred.reserve_activate
      @delayer.new do
        next if deferred.spoiled?
        begin
          fiber.resume(deferred).accept_request(worker: self,
                                                deferred: deferred)
        rescue Delayer::Deferred::SequenceError => err
          err.deferred = deferred
          raise
        end
      end
      nil
    end

    # Awaitから復帰した時に呼ばれる。
    # ==== Args
    # [response] Awaitの結果(Delayer::Deferred::Response::Base)
    # [deferred] 現在実行中のDeferred
    def give_response(response, deferred)
      @delayer.new do
        next if deferred.spoiled?
        deferred.exit_await
        fiber.resume(response).accept_request(worker: self,
                                              deferred: deferred)
      end
      nil
    end

    # Tools#pass から復帰した時に呼ばれる。
    # ==== Args
    # [deferred] 現在実行中のDeferred
    def resume_pass(deferred)
      deferred.exit_pass
      @delayer.new do
        next if deferred.spoiled?
        fiber.resume(nil).accept_request(worker: self,
                                         deferred: deferred)
      end
    end

    private

    def fiber
      @fiber ||= Fiber.new{|response|
        loop do
          response = wait_and_activate(response)
          case response.value
          when Delayer::Deferred::SequenceError
            raise response.value
          end
        end
      }.tap{|f| f.resume(@initial); @initial = nil }
    end

    def wait_and_activate(argument)
      response = catch(:success) do
        failed = catch(:__deferredable_fail) do
          begin
            if argument.value.is_a? Deferredable::Awaitable
              throw :success, +argument.value
            else
              defer = Fiber.yield(Request::NEXT_WORKER)
              res = defer.activate(argument)
              if res.is_a? Delayer::Deferred::Deferredable::Awaitable
                defer.add_awaited(res)
              end
            end
            throw :success, res
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
