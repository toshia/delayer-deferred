# -*- coding: utf-8 -*-
require "delayer"
require "delayer/deferred/deferred"

class Enumerator
  def deach(delayer=Delayer, &proc)
    delayer.Deferred.new.next do
      begin
        loop do
          proc.call(self.next())
          if delayer.expire?
            break deach(delayer, &proc) end end
      rescue StopIteration
        nil end end
  end
end
