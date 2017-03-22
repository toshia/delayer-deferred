# -*- coding: utf-8 -*-
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
        puts "fiber.resume(#{deferred.inspect})"
        fiber.resume(deferred)
        if deferred.has_child?
          self.push(deferred.child)
        else
          puts "#{deferred.inspect} dont have child"
          # TODO: childが入ったら続行
        end
      end
    end

    private

    def fiber
      @fiber ||= Fiber.new{|response|
        loop do
          response = catch(:success) do
            failed = catch(:__deferredable_fail) do
              begin
                throw :success, Fiber.yield(nil).activate(response)
              rescue Exception => err
                throw :__deferredable_fail, err
              end
            end
            Response::Ng.new(failed)
          end
          unless response.is_a?(Response::Base)
            response = Response::Ok.new(response)
          end
        end
      }.tap{|f| f.resume(@initial); @initial = nil }
    end
  end
end
