# -*- coding: utf-8 -*-
class Thread
  include ::Delayer::Deferred::Deferredable

  def self.delayer
    Delayer
  end

  alias _deferredable_trap initialize
  def initialize(*args, &proc)
    _deferredable_trap(*args, &_deferredable_trap_proc(&proc)) end

  alias :deferredable_cancel :cancel
  def cancel
    deferredable_cancel
    kill end

  private
  def _deferredable_trap_proc
    proc = Proc.new
    ->(*args) do
      begin
        result = proc.call(*args)
        self.call(result)
        result
      rescue Exception => exception
        self.fail(exception) end end end
end
