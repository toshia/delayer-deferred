# coding: utf-8
require "delayer"
require "delayer/deferred/version"
require "delayer/deferred/deferredable"
require "delayer/deferred/deferred"
require "delayer/deferred/thread"
require "delayer/deferred/enumerator"
require "delayer/deferred/enumerable"

module Delayer
  module Deferred
    extend self

    #真ならデバッグ情報を集める
    attr_accessor :debug

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
    # [defer] 終了を待つDeferredオブジェクト
    # [*follow] 他のDeferredオブジェクト
    # ==== Return
    # Deferred
    def when(defer, *follow)
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
      delayer.Deferred.Thread.new do
        if Kernel.system(*args)
          $?
        else
          delayer.Deferred.fail($?) end end end
  end

  module Extend
    def Deferred
      @deferred ||= begin
                      the_delayer = self
                      Class.new(::Delayer::Deferred::Deferred) {
                        define_singleton_method(:delayer) {
                          the_delayer } } end
    end
  end
end

Delayer::Deferred.debug = false
