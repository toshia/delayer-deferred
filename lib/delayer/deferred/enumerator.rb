# -*- coding: utf-8 -*-
require "delayer"
require "delayer/deferred/deferred"

class Enumerator
  def deach(delayer=Delayer, &proc)
    delayer.Deferred.new.next do
      self.each do |node|
        delayer.Deferred.pass
        proc.(node)
      end
    end
  end
end
