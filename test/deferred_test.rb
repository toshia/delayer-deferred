# -*- coding: utf-8 -*-

require_relative 'helper'

describe(Delayer::Deferred) do
  include TestUtils

  before do
    Delayer.default = Delayer.generate_class
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
    assert_equal false, failure
    assert_equal uuid, result
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

  it "assign twice" do
    succeed = false
    delayer = Delayer.generate_class
    assert_raises(Delayer::Deferred::MultipleAssignmentError) do
      eval_all_events(delayer) do
        defer = delayer.Deferred.new.next {
          succeed = 0
        }
        defer.next{ succeed = 1 }
        defer.next{ succeed = 2 }
      end
    end
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

    it "default deferred" do
      result = failure = false
      eval_all_events do
        Delayer::Deferred::Deferred.when(
          Delayer::Deferred::Deferred.new.next{ 1 },
          Delayer::Deferred::Deferred.new.next{ 2 },
          Delayer::Deferred::Deferred.new.next{ 3 }
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

    it "no deferred given" do
      result = failure = false
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.when().next{ |values|
          result = values
        }.trap{ |exception|
          failure = exception }  end
      assert_equal false, failure
      assert_empty result
    end

    it "empty array given" do
      result = failure = false
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.when([]).next{ |values|
          result = values
        }.trap{ |exception|
          failure = exception }  end
      assert_equal false, failure
      assert_empty result
    end

    it "no deferred given for default delayer" do
      result = failure = false
      eval_all_events do
        Delayer::Deferred::Deferred.when().next{ |values|
          result = values
        }.trap{ |exception|
          failure = exception }  end
      assert_equal false, failure
      assert_empty result
    end

    it "no deferred given for delayer module" do
      result = failure = false
      eval_all_events do
        Delayer::Deferred.when().next{ |values|
          result = values
        }.trap{ |exception|
          failure = exception }  end
      assert_equal false, failure
      assert_empty result
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

  describe 'recursive delayer' do
    it 'Deferred#next call in Deferred.next' do
      delayer = Delayer.generate_class
      buf = []
      erra = errb = errc = nil
      eval_all_events(delayer) do
        delayer.Deferred.next{
          buf << 'begin A'
          delayer.run
          buf << 'end A'
        }.trap{|err|
          erra = err
        }
        delayer.Deferred.next{
          buf << 'begin B'
          delayer.run
          buf << 'end B'
        }.trap{|err|
          errb = err
        }
        delayer.Deferred.next{
          buf << 'begin C'
          delayer.run
          buf << 'end C'
        }.trap{|err|
          errc = err
        }

      end
      refute erra
      refute errb
      refute errc
      assert_includes buf, 'begin A'
      assert_includes buf, 'end A'
      assert_includes buf, 'begin B'
      assert_includes buf, 'end B'
      assert_includes buf, 'begin C'
      assert_includes buf, 'end C'
    end
  end

  describe "Deferredable#system" do
    it "command successed" do
      succeed = failure = false
      delayer = Delayer.generate_class
      eval_all_events(delayer) do
        delayer.Deferred.system("/bin/sh", "-c", "exit 0").next{ |value|
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
        delayer.Deferred.system("/bin/sh", "-c", "exit 1").next{ |value|
          succeed = value
        }.trap{ |exception|
          failure = exception } end
      refute succeed, "next block did not called"
      assert_instance_of Delayer::Deferred::ForeignCommandAborted, failure
      assert failure.process.exited?, "command exited"
      assert_equal 1, failure.process.exitstatus, "command exit status is 1"
    end
  end

  describe 'Deferredable#+@' do
    it 'stops +@ deferred chain, then it returns result after receiver completed' do
      delayer = Delayer.generate_class
      log = Array.new
      eval_all_events(delayer) do
        delayer.Deferred.new.next{
          log << :a1
          b = delayer.Deferred.new.next{
            log << :b1 << +delayer.Deferred.new.next{
              log << :c1 << +delayer.Deferred.new.next{
                log << :d1
                :d2
              }
              :c2
            }
            :b2
          }
          log << :a2 << +b << :a3
        }
      end

      assert_equal [:a1, :a2, :b1, :c1, :d1, :d2, :c2, :b2, :a3], log, 'incorrect call order'
    end

    it 'fails receiver of +@, then fails callee Deferred' do
      delayer = Delayer.generate_class
      log = Array.new
      eval_all_events(delayer) do
        delayer.Deferred.new.next{
          log << :a1
          b = delayer.Deferred.new.next{
            log << :b1
            delayer.Deferred.fail(:be)
            :b2
          }
          log << :a2 << +b << :a3
        }.trap do |err|
          log << :ae << err
        end
      end

      assert_equal [:a1, :a2, :b1, :ae, :be], log, 'incorrect call order'

    end
  end
end
