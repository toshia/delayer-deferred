# -*- coding: utf-8 -*-

require_relative 'helper'

describe(Thread) do
  include TestUtils

  before do
    Delayer.default = Delayer.generate_class
  end

  describe 'Generic thread operation' do
    describe 'Exception in thread' do
      before do
        @error = Class.new(RuntimeError)
        @thread = Thread.new {
          raise @error
        }
      end

      it 'should takes the exception' do
        assert_raises(@error) do
          @thread.value
        end
      end
    end
  end

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
    delayer = Delayer.generate_class
    succeed = failure = recover = false
    uuid = SecureRandom.uuid
    eval_all_events(delayer) do
      delayer.Deferred.Thread.new {
        Delayer::Deferred.fail(uuid)
      }.next {
        succeed = true
      }.trap { |value|
        failure = value
      }.next {
        recover = true } end
    refute succeed, "Raised exception but it was executed successed route."
    assert_kind_of UncaughtThrowError , failure, "trap block takes incorrect value"
    assert recover, "next block did not executed when after trap"
  end

  it "exception handling" do
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
