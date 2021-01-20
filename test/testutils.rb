module TestUtils
  def eval_all_events(delayer=Delayer, &block)
    native = Thread.list
    result = block&.call()
    until delayer.empty? && (Thread.list - native).empty?
      delayer.run
      Thread.pass
    end
    result
  end
end
