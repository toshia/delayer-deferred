# -*- coding: utf-8 -*-
require "delayer/deferred/version"

module Delayer::Deferred
  module Deferredable; end
end

require "delayer/deferred/deferredable/awaitable"
require "delayer/deferred/deferredable/chainable"
require "delayer/deferred/deferredable/graph"
require "delayer/deferred/deferredable/node_sequence"
require "delayer/deferred/deferredable/trigger"
