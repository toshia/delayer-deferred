# -*- coding: utf-8 -*-
require "delayer/deferred/version"
require "delayer/deferred/result_container"

# なんでもDeferred
module Delayer::Deferred::Deferredable
  Callback = Struct.new(*%i<ok ng backtrace>)
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

  # _self_ が終了して結果が出るまで呼び出し側のDeferredを停止し、 _self_ の結果を返す。
  # 呼び出し側はDeferredブロック内でなければならないが、 _Deferred#next_ を使わずに
  # 直接戻り値を得ることが出来る。
  # _self_ が失敗した場合は、呼び出し側のDeferredの直近の _trap_ ブロックが呼ばれる。
  def +@
    interrupt = Fiber.yield(self)
    if interrupt.ok?
      interrupt.value
    else
      Delayer::Deferred.fail(interrupt.value)
    end
  end

  # この一連のDeferredをこれ以上実行しない
  def cancel
    @callback = Callback.new(CallbackDefaultOK,
                             CallbackDefaultNG).freeze end

  def callback
    @callback ||= Callback.new(CallbackDefaultOK,
                               CallbackDefaultNG) end

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
    delayer.new do
      result, fiber = delayer.Deferred.fiber do
        begin
          result = catch(:__deferredable_fail) do
            Delayer::Deferred::ResultContainer.new(true, _execute(stat, value))
          end
          if result.is_a?(Delayer::Deferred::ResultContainer)
            result
          else
            Delayer::Deferred::ResultContainer.new(false, result)
          end
        rescue Exception => exception
          Delayer::Deferred::ResultContainer.new(false, exception)
        end
      end
      #_wait_fiber(fiber, nil)
      if fiber
        _fiber_stopped(result){|i| _wait_fiber(fiber, i) }
      else
        _fiber_completed(result)
      end
    end
  end


  def _execute(stat, value)
    callback[stat].call(value)
  end

  def _wait_fiber(fiber, resume_value)
    result = fiber.resume(resume_value)
    if result.is_a?(Delayer::Deferred::ResultContainer)
      _fiber_completed(result)
    else
      _fiber_stopped(result){|i| _wait_fiber(fiber, i) }
    end
  end

  # Deferredブロックが最後まで終わり、これ以上やることがない時に呼ばれる
  def _fiber_completed(result)
    result_value = result.value
    if result.ok?
      if result_value.is_a?(Delayer::Deferred::Deferredable)
        result_value.next{|v|
          _success_action(v)
        }.trap{|v|
          _fail_action(v)
        }
      else
        _success_action(result_value)
      end
    else
      _fail_action(result_value)
    end
  end

  # Deferredable#@+によって停止され、 _defer_ の完了次第処理を再開する必要がある時に呼ばれる
  def _fiber_stopped(defer, &cont)
    defer.next{|v|
      cont.(Delayer::Deferred::ResultContainer.new(true, v))
    }.trap{|v|
      cont.(Delayer::Deferred::ResultContainer.new(false, v))
    }
  end

  def _post(kind, &proc)
    raise Delayer::Deferred::MultipleAssignmentError, "It was already assigned next or trap block." if defined?(@next)
    @next = delayer.Deferred.new(self)
    @next.callback[kind] = proc
    if defined?(@next_call_stat) and defined?(@next_call_value)
      @next.__send__({ok: :call, ng: :fail}[@next_call_stat], @next_call_value)
    elsif defined?(@follow) and @follow.nil?
      call end
    @next end

  def register_next_call(stat, value)
    @next_call_stat, @next_call_value = stat, value
    self end

  def _success_action(obj)
    if defined?(@next)
      @next.call(obj)
    else
      register_next_call(:ok, obj)
    end
  end

  def _fail_action(err_obj)
    if defined?(@next)
      @next.fail(err_obj)
    else
      register_next_call(:ng, err_obj)
    end
  end

end
