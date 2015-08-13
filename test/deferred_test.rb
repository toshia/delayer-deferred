# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'minitest/autorun'

require 'delayer/deferred'
require 'securerandom'
require 'set'

describe(Delayer::Deferred) do
  before do
    Delayer.default = Delayer.generate_class
  end

  def eval_all_events(delayer=Delayer)
    native = Thread.list
    result = yield if block_given?
    while not(delayer.empty? and (Thread.list - native).empty?)
      delayer.run
      Thread.pass
    end
    result
  end

  it "defer with Deferred#next" do
    succeed = failure = false
    eval_all_events do
    Delayer::Deferred::Deferred.new.next{
      succeed = true
    }.trap{ |exception|
      failure = exception } end
    assert_equal false, failure
    assert succeed, "Deferred did not executed."
  end

  it "defer with another Delayer" do
    succeed = failure = false
    delayer = Delayer.generate_class
    eval_all_events(delayer) do
      delayer.Deferred.new.next {
        succeed = true
      }.trap{ |exception|
        failure = exception } end
    assert_equal false, failure
    assert succeed, "Deferred did not executed."
  end

  it "error handling" do
    succeed = failure = recover = false
    uuid = SecureRandom.uuid
    eval_all_events do
      Delayer::Deferred::Deferred.new.next {
        Delayer::Deferred.fail(uuid)
      }.next {
        succeed = true
      }.trap { |value|
        failure = value
      }.next {
        recover = true } end
    refute succeed, "Raised exception but it was executed successed route."
    assert_equal uuid, failure, "trap block takes incorrect value"
    assert recover, "next block did not executed when after trap"
  end

  it "exception handling" do
    succeed = failure = recover = false
    eval_all_events do
      Delayer::Deferred::Deferred.new.next {
        raise 'error test'
      }.next {
        succeed = true
      }.trap {
        failure = true
      }.next {
        recover = true } end
    refute succeed, "Raised exception but it was executed successed route."
    assert failure, "trap block did not executed"
    assert recover, "next block did not executed when after trap"
  end

  it "wait end of Deferredable if Deferredable block returns Deferredable" do
    result = failure = false
    delayer = Delayer.generate_class
    uuid = SecureRandom.uuid
    eval_all_events(delayer) do
      delayer.Deferred.new.next{
        delayer.Deferred.new.next{
          uuid }
      }.next{ |value|
        result = value
      }.trap{ |exception|
        failure = exception }
    end
    assert_equal uuid, result
    assert_equal false, failure
  end

  it "join Deferredable#next after end of previous Deferredable" do
    succeed = failure = false
    delayer = Delayer.generate_class
    deferredable = eval_all_events(delayer) do
      delayer.Deferred.new.next {
        true
      } end
    eval_all_events(delayer) do
      deferredable.next{ |value|
        succeed = value
      }.trap{ |exception|
        failure = exception } end
    assert_equal false, failure
    assert succeed, "Deferred did not executed."
  end

  describe "Deferred.when" do
    it "give 3 deferred" do
      result = failure = false
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.when(
          delayer.Deferred.new.next{ 1 },
          delayer.Deferred.new.next{ 2 },
          delayer.Deferred.new.next{ 3 }
        ).next{ |values|
          result = values
        }.trap{ |exception|
          failure = exception }  end
      assert_equal false, failure
      assert_equal [1,2,3], result
    end

    it "give that is not Deferredable" do
      result = failure = false
      delayer = Delayer.generate_class
      assert_raises(TypeError) do
        eval_all_events(delayer) do
          delayer.Deferred.when(
            delayer.Deferred.new.next{ 1 },
            2,
            delayer.Deferred.new.next{ 3 }
          ).next{ |values|
            result = values
          }.trap{ |exception|
            failure = exception } end end
      assert_equal false, failure
      assert_equal false, result
    end

    it "execute trap block if failed" do
      result = failure = false
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.when(
          delayer.Deferred.new.next{ 1 },
          delayer.Deferred.new.next{ raise },
          delayer.Deferred.new.next{ 3 }
        ).next{ |values|
          result = values
        }.trap{ |exception|
          failure = exception }  end
      assert_kind_of RuntimeError, failure
      assert_equal false, result
    end
  end

  describe "cancel" do
    it "stops deferred chain" do
      succeed = failure = false
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.new.next {
          succeed = true
        }.trap{ |exception|
          failure = exception }.cancel end
      assert_equal false, failure
      assert_equal false, succeed, "Deferred executed."
    end
  end

  describe "Deferredable#system" do
    it "command successed" do
      succeed = failure = false
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.system("ruby", "-e", "exit 0").next{ |value|
          succeed = value
        }.trap{ |exception|
          failure = exception } end
      assert_equal false, failure
      assert succeed, "next block called"
    end

    it "command failed" do
      succeed = failure = false
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.system("ruby", "-e", "exit 1").next{ |value|
          succeed = value
        }.trap{ |exception|
          failure = exception } end
      refute succeed, "next block did not called"
      assert failure.exited?, "command exited"
      assert_equal 1, failure.exitstatus, "command exit status is 1"
    end
  end
end
