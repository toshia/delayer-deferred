# -*- coding: utf-8 -*-

Delayer::Deferred::ResultContainer = Struct.new(:success_flag, :value) do
  def ok?
    success_flag
  end

  def ng?
    !success_flag
  end
end
