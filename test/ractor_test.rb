# frozen_string_literal: true

require_relative 'helper'

describe(Ractor) do
  include TestUtils

  before do
    @delayer = Delayer.generate_class
  end

  it 'Execute in Ractor Deferred.new' do
    assert_equal_deferred('another', delayer: @delayer) do
      @delayer.Deferred.new(parallel: true) do
        Ractor.main == Ractor.current ? 'main' : 'another' # expect 'another'
      end
    end
  end

  it 'Execute in Ractor Deferred.next' do
    assert_equal_deferred('another', delayer: @delayer) do
      @delayer.Deferred.new.next(parallel: true) do
        Ractor.main == Ractor.current ? 'main' : 'another' # expect 'another'
      end
    end
  end

  it 'Execute in Ractor Deferred.trap' do
    assert_equal_deferred('another', delayer: @delayer) do
      @delayer.Deferred.new {
        Delayer::Deferred.fail 'error!'
      }.trap(parallel: true) do
        Ractor.main == Ractor.current ? 'main' : 'another' # expect 'another'
      end
    end
  end

  #
  # Chain Thread
  #

  it 'Execute in Ractor Thread.next' do
    assert_equal_deferred('another', delayer: @delayer) do
      @delayer.Deferred.Thread.new { 'hoge' }.next(parallel: true) do
        Ractor.main == Ractor.current ? 'main' : 'another' # expect 'another'
      end
    end
  end

  it 'Execute in Ractor Deferred.trap' do
    assert_equal_deferred('another', delayer: @delayer) do
      @delayer.Deferred.Thread.new {
        raise 'error!'
      }.trap(parallel: true) do
        Ractor.main == Ractor.current ? 'main' : 'another' # expect 'another'
      end
    end
  end
end
