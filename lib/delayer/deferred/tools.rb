# -*- coding: utf-8 -*-
require 'delayer/deferred/error'

module Delayer::Deferred
  module Tools
    def next(&proc)
      new.next(&proc) end

    def trap(&proc)
      new.trap(&proc) end

    # 実行中のDeferredを失敗させる。raiseと違って、Exception以外のオブジェクトをtrap()に渡すことができる。
    # Deferredのnextとtrapの中でだけ呼び出すことができる。
    # ==== Args
    # [value] trap()に渡す値
    # ==== Throw
    # :__deferredable_fail をthrowする
    def fail(value)
      throw(:__deferredable_fail, value) end

    # 実行中のDeferredを、Delayerのタイムリミットが来ている場合に限り一旦中断する。
    # 長期に渡る可能性のある処理で、必要に応じて他のタスクを先に実行してもよい場合に呼び出す。
    def pass
      Fiber.yield(Request::PASS) if delayer.expire?
    end

    # 複数のdeferredを引数に取って、それら全ての実行が終了したら、
    # その結果を引数の順番通りに格納したArrayを引数に呼ばれるDeferredを返す。
    # 引数のDeferredが一つでも失敗するとこのメソッドの返すDeferredも失敗する。
    # ==== Args
    # [*args] 終了を待つDeferredオブジェクト
    # ==== Return
    # Deferred
    def when(*args)
      return self.next{[]} if args.empty?
      args = args.flatten
      args.each_with_index{|d, index|
        unless d.is_a?(Deferredable::Chainable) || d.is_a?(Deferredable::Awaitable)
          raise TypeError, "Argument #{index} of Deferred.when must be #{Deferredable::Chainable}, but given #{d.class}"
        end
        if d.respond_to?(:has_child?) && d.has_child?
          raise "Already assigned child for argument #{index}"
        end
      }
      defer, *follow = *args
      defer.next{|res|
        [res, *follow.map{|d| +d }]
      }
    end
    # Kernel#systemを呼び出して、コマンドが成功たら成功するDeferredを返す。
    # 失敗した場合、trap{}ブロックには $? の値(Process::Status)か、例外が発生した場合それが渡される
    # ==== Args
    # [*args] Kernel#spawn の引数
    # ==== Return
    # Deferred
    def system(*args)
      delayer.Deferred.Thread.new {
        Process.waitpid2(Kernel.spawn(*args))
      }.next{|_pid, status|
        if status && status.success?
          status
        else
          raise ForeignCommandAborted.new("command aborted: #{args.join(' ')}", process: status) end
      }
    end
  end
end
