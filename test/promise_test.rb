# -*- coding: utf-8 -*-

require_relative 'helper'

describe(Delayer::Deferred::Promise) do
  include TestUtils

  before do
    Delayer.default = Delayer.generate_class
    @delayer = Delayer.generate_class
  end

  describe 'get instance' do
    it 'default delayer' do
      assert_instance_of Delayer::Deferred::Promise, Delayer::Deferred::Promise.new
    end

    it 'another delayer' do
      promise = @delayer.Promise.new
      assert_instance_of @delayer.Promise, promise
    end

    describe "with block" do
      before do
        @promise = @delayer.Promise.new{ ; }
      end

      it 'was generated' do
        assert_kind_of Delayer::Deferred::Chain::Next, @promise
      end

      it "doesn't have child" do
        refute @promise.has_child?
      end
    end
  end

  describe 'chain' do
    before do
      @promise = @delayer.Promise.new(true)
    end

    describe 'next' do
      before do
        @record = nil
        @chain = @promise.next{|x| @record = x + 1 }
      end

      it 'should execute next block if called promise#call' do
        val = rand(1000)
        eval_all_events(@delayer) do
          @promise.call(val)
        end
        assert_equal val + 1, @record, ->{ "next block did not executed.\n[[#{@chain.graph_draw}]]" }
      end

      it "shouldn't execute next block if called promise#fail" do
        val = rand(1000)
        eval_all_events(@delayer) do
          @promise.fail(val)
        end
        refute_equal val + 1, @record, ->{ "next block did executed.\n[[#{@chain.graph_draw}]]" }
      end
    end

    describe 'trap' do
      before do
        @record = nil
        @chain = @promise.trap{|x| @record = x + 1 }
      end

      it 'should execute trap block if called promise#fail' do
        val = rand(1000)
        eval_all_events(@delayer) do
          @promise.fail(val)
        end
        assert_equal val + 1, @record, ->{ "trap block did not executed.\n[[#{@chain.graph_draw}]]" }
      end

      it "shouldn't execute trap block if called promise#call" do
        val = rand(1000)
        eval_all_events(@delayer) do
          @promise.call(val)
        end
        refute_equal val + 1, @record, ->{ "trap block did executed.\n[[#{@chain.graph_draw}]]" }
      end
    end

  end

end
