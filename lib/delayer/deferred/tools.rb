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

    # 複数のdeferredを引数に取って、それら全ての実行が終了したら、
    # その結果を引数の順番通りに格納したArrayを引数に呼ばれるDeferredを返す。
    # 引数のDeferredが一つでも失敗するとこのメソッドの返すDeferredも失敗する。
    # ==== Args
    # [*args] 終了を待つDeferredオブジェクト
    # ==== Return
    # Deferred
    def when(*args)
      return self.next{[]} if args.empty?
      defer, *follow = args
      raise TypeError, "Argument of Deferred.when must be Delayer::Deferred::Deferredable" unless defer.is_a? Delayer::Deferred::Deferredable
      if follow.empty?
        defer.next{|res| [res] }
      else
        remain = self.when(*follow)
        defer.next do |res|
          remain.next do |follow_res|
            follow_res.unshift(res) end end end end

    # Kernel#systemを呼び出して、コマンドが成功たら成功するDeferredを返す。
    # 失敗した場合、trap{}ブロックには $? の値(Process::Status)か、例外が発生した場合それが渡される
    # ==== Args
    # [*args] Kernel#system の引数
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
