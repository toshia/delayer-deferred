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
    yield if block_given?
    delayer.run while not(delayer.empty? and (Thread.list - native).empty?)
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

  describe "Thread acts as deferred" do
    it "defer with Deferred#next" do
      thread = succeed = result = false
      uuid = SecureRandom.uuid
      eval_all_events do
        Thread.new {
          thread = true
          uuid
        }.next do |param|
          succeed = true
          result = param
        end end
      assert thread, "Thread did not executed."
      assert succeed, "next block did not executed."
      assert_equal uuid, result
    end

    it "defer with another Delayer" do
      thread = succeed = failure = result = false
      uuid = SecureRandom.uuid
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.Thread.new {
          thread = true
          uuid
        }.next{ |param|
          succeed = true
          result = param
        }.trap{ |exception|
          failure = exception } end
      assert_equal false, failure
      assert thread, "Thread did not executed."
      assert succeed, "next block did not executed."
      assert_equal uuid, result
    end

    it "error handling" do
      succeed = failure = recover = false
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.Thread.new {
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

    it "wait end of Deferredable if Deferredable block returns Thread" do
      result = failure = false
      delayer = Delayer.generate_class
      uuid = SecureRandom.uuid
      eval_all_events(delayer) do
        delayer.Deferred.new.next{
          delayer.Deferred.Thread.new{
            uuid }
        }.next{ |value|
          result = value
        }.trap{ |exception|
          failure = exception }
      end
      assert_equal uuid, result
      assert_equal false, failure
    end
  end
end
