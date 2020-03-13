# -*- coding: utf-8 -*-
require 'pry'
require_relative 'helper'

describe(Delayer::Deferred) do
  include TestUtils

  before do
    @delayer = Delayer.generate_class
  end
  # delayer.new(delay: Time.new) { a << 0 }

  it "Deferred.sleep returns promise when resolve after n minutes" do
    lst = []
    eval_all_events(@delayer) do
      @delayer.Deferred.sleep(0.1).next do
        lst << 1
      end
      @delayer.Deferred.next do
        lst << 2
      end
    end
    sleep 0.2
    @delayer.run
    #assert_equal false, failure
    assert_equal [2, 1], lst, "Deferred did not executed."
  end
end
