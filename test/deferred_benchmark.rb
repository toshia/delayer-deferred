# -*- coding: utf-8 -*-

require 'benchmark'
require 'bundler/setup'
require 'delayer/deferred'
require_relative 'testutils'

Benchmark.bmbm do |r|
  extend TestUtils
  n = 10000

  r.report 'construct' do
    delayer = Delayer.generate_class
    n.times do
      delayer.Deferred.new
    end
  end

  r.report 'register next block' do
    delayer = Delayer.generate_class
    n.times do
      delayer.Deferred.new.next do |x|
        x
      end
    end
  end

  r.report 'execute next block' do
    delayer = Delayer.generate_class
    eval_all_events(delayer) do
      n.times do
        delayer.Deferred.new.next do |x|
          x
        end
      end
    end
  end

  r.report 'double next block' do
    delayer = Delayer.generate_class
    eval_all_events(delayer) do
      n.times do
        delayer.Deferred.new.next { |x|
          x
        }.next do |x|
          x
        end
      end
    end
  end

  r.report 'trap block' do
    delayer = Delayer.generate_class
    eval_all_events(delayer) do
      n.times do
        delayer.Deferred.new.next { |x|
          x
        }.trap do |x|
          x
        end
      end
    end
  end
end
