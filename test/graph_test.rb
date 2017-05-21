# -*- coding: utf-8 -*-
require_relative 'helper'

describe(Delayer::Deferred) do
  include TestUtils

  before do
    Delayer.default = Delayer.generate_class
  end

  describe 'auto execution Promise' do
    it 'should include Promise result of Promise.graph' do
      promise = Delayer::Deferred::Promise.new
      assert_includes promise.graph, 'egg', ->{"[[#{promise.graph_draw}]]"}
      assert_includes promise.graph, 'reserved', ->{"[[#{promise.graph_draw}]]"}
    end
  end

  describe 'Promise' do
    it 'should include Promise result of Promise.graph' do
      promise = Delayer::Deferred::Promise.new(true)
      assert_includes promise.graph, 'egg', ->{"[[#{promise.graph_draw}]]"}
      assert_includes promise.graph, 'fresh', ->{"[[#{promise.graph_draw}]]"}
    end
  end

  describe 'Chain' do
    it 'should include ' do
      promise = Delayer::Deferred::Promise.new.next{ ; }
      assert_includes promise.graph, 'graph_test.rb', ->{"[[#{promise.graph_draw}]]"}
    end
  end

  describe 'Awaiting' do
    it 'await' do
      promise_a = Delayer::Deferred::Promise.new(true).next{ |buf|
        buf << :a
      }.next{ |buf|
        buf << :b
      }.trap{ |buf|
        buf << :c
      }
      promise_b = Delayer::Deferred::Promise.new.next{
        +promise_a << :e
      }.trap{ |buf|
        buf << :f
      }
      eval_all_events
    end
  end

end
