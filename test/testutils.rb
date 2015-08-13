module TestUtils
  def eval_all_events(delayer=Delayer)
    native = Thread.list
    result = yield if block_given?
    while not(delayer.empty? and (Thread.list - native).empty?)
      delayer.run
      Thread.pass
    end
    result
  end
end
