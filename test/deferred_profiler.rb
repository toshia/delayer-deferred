# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'delayer/deferred'
require 'ruby-prof'
require_relative 'testutils'

extend TestUtils
n = 1000

RubyProf.start
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

result = RubyProf.stop
printer = RubyProf::CallTreePrinter.new(result)
path = File.expand_path(File.join(__dir__, '..', 'profile', Time.new.strftime('%Y-%m-%d-%H%M%S')))
FileUtils.mkdir_p(path)
puts "profile: writing to #{path}"
printer.print(path: path)
puts 'profile: done.'
