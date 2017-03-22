# -*- coding: utf-8 -*-
require "delayer/deferred/response"

module Delayer::Deferred
  class Worker
    def initialize(delayer:, initial:)
      @delayer, @initial = delayer, initial
    end

    def push(deferred)
      @delayer.new do
        puts "fiber.resume(#{deferred.inspect})"
        fiber.resume(deferred)
        if deferred.has_child?
          self.push(deferred.child)
        else
          puts "#{deferred.inspect} dont have child"
          # TODO: childが入ったら続行
        end
      end
    end

    private

    def fiber
      @fiber ||= Fiber.new{|response|
        loop do
          response = catch(:success) do
            failed = catch(:__deferredable_fail) do
              begin
                throw :success, Fiber.yield(nil).activate(response)
              rescue Exception => err
                throw :__deferredable_fail, err
              end
            end
            Response::Ng.new(failed)
          end
          unless response.is_a?(Response::Base)
            response = Response::Ok.new(response)
          end
        end
      }.tap{|f| f.resume(@initial); @initial = nil }
    end
  end
end
