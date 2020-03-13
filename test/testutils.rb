module TestUtils
  def eval_all_events(delayer=Delayer, &block)
    native = Thread.list
    result = block&.call()
    while not(delayer.empty? and (Thread.list - native).empty?)
      delayer.run
      Thread.pass
    end
    result
  end
end
