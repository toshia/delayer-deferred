# -*- coding: utf-8 -*-
require "delayer/deferred/version"

# なんでもDeferred
module Delayer::Deferred::Deferredable
  Callback = Struct.new(*%i<ok ng backtrace>)
  BackTrace = Struct.new(*%i<ok ng>)
  CallbackDefaultOK = lambda{ |x| x }
  CallbackDefaultNG = lambda{ |err| Delayer::Deferred.fail(err) }

  # このDeferredが成功した場合の処理を追加する。
  # 新しいDeferredのインスタンスを返す
  def next(&proc)
    _post(:ok, &proc) end
  alias deferred next

  # このDeferredが失敗した場合の処理を追加する。
  # 新しいDeferredのインスタンスを返す
  def trap(&proc)
    _post(:ng, &proc) end
  alias error trap

  # Deferredを直ちに実行する
  def call(value = nil)
    _call(:ok, value) end

  # Deferredを直ちに失敗させる
  def fail(exception = nil)
    _call(:ng, exception) end

  # この一連のDeferredをこれ以上実行しない
  def cancel
    @callback = Callback.new(CallbackDefaultOK,
                             CallbackDefaultNG,
                             BackTrace.new(nil, nil).freeze).freeze end

  def callback
    @callback ||= Callback.new(CallbackDefaultOK,
                               CallbackDefaultNG,
                               BackTrace.new(nil, nil)) end

  # second 秒待って次を実行する
  # ==== Args
  # [second] 待つ秒数(second)
  # ==== Return
  # Deferred
  def wait(second)
    self.next{ Thread.new{ sleep(second) } } end

  private

  def delayer
    self.class.delayer
  end

  def _call(stat = :ok, value = nil)
    begin
      catch(:__deferredable_success) do
        failed = catch(:__deferredable_fail) do
          n_value = _execute(stat, value)
          if n_value.is_a? Delayer::Deferred::Deferredable
            n_value.next{ |result|
              @next.call(result)
            }.trap{ |exception|
              @next.fail(exception) }
          else
            if defined?(@next)
              delayer.new{ @next.call(n_value) }
            else
              register_next_call(:ok, n_value) end end
          throw :__deferredable_success end
        _fail_action(failed) end
    rescue Exception => exception
      _fail_action(exception) end end

  def _execute(stat, value)
    callback[stat].call(value) end

  def _post(kind, &proc)
    @next = delayer.Deferred.new(self)
    @next.callback[kind] = proc
    @next.callback.backtrace[kind] = caller(1)
    if defined?(@next_call_stat) and defined?(@next_call_value)
      @next.__send__({ok: :call, ng: :fail}[@next_call_stat], @next_call_value)
    elsif defined?(@follow) and @follow.nil?
      call end
    @next end

  def register_next_call(stat, value)
    @next_call_stat, @next_call_value = stat, value
    self end

  def _fail_action(err_obj)
    if defined?(@next)
      delayer.new{ @next.fail(err_obj) }
    else
      register_next_call(:ng, err_obj) end end

end
