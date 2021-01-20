# -*- coding: utf-8 -*-

require 'delayer'
require 'delayer/deferred/enumerator'

module Enumerable
  # 遅延each。あとで実行されるし、あんまりループに時間がかかるようなら一旦ループを終了する
  def deach(delayer=Delayer, &proc)
    to_enum.deach(delayer, &proc)
  end
end
