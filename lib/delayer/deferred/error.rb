# -*- coding: utf-8 -*-

module Delayer::Deferred
  Error = Class.new(StandardError)

  class ForeignCommandAborted < Error
    attr_reader :process
    def initialize(message, process:)
      super(message)
      @process = process
    end
  end

  MultipleAssignmentError = Class.new(Error)
  SequenceError = Class.new(Error)
end
