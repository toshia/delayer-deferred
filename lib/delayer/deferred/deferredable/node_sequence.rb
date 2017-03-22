# -*- coding: utf-8 -*-
require 'delayer/deferred/error'

module Delayer::Deferred::Deferredable
  module NodeSequence
    class Sequence
      attr_reader :name

      def initialize(name)
        @name = name.to_sym
        @map = {}
        @exceptions = Hash.new(Delayer::Deferred::SequenceError)
      end

      def add(seq, flow = seq.name)
        @map[flow] = seq
        self
      end

      def exception(exc, flow)
        @exceptions[flow] = exc
      end

      def pull(flow)
        if @map.has_key?(flow.to_sym)
          @map[flow.to_sym]
        else
          raise @exceptions[flow.to_sym], "Invalid sequence flow `#{name}' to `#{flow}'."
        end
      end

      def inspect
        "#<#{self.class}: #{name}>"
      end
    end

    FRESH     = Sequence.new(:fresh)
    CONNECTED = Sequence.new(:connected)      # 子がいる、未実行
    RESERVED  = Sequence.new(:reserved)       # 実行キュー待ち
    RESERVED_C= Sequence.new(:reserved)       # 実行キュー待ち(子がいる)
    RUN       = Sequence.new(:run)            # 実行中
    RUN_C     = Sequence.new(:run)            # 実行中(子がいる)
    CALL_CHILD= Sequence.new(:call_child)     # 完了、子がいる
    STOP      = Sequence.new(:stop)           # 完了、子なし
    WAIT      = Sequence.new(:wait)           # 完了、オブザーバ登録済み
    BURST_OUT = Sequence.new(:burst_out)      # 完了、オブザーバ登録済み、子追加済み
    ROTTEN    = Sequence.new(:rotten).freeze  # 終了

    FRESH
      .add(CONNECTED, :get_child)
      .add(RESERVED, :reserve).freeze
    CONNECTED
      .add(RESERVED_C, :reserve)
      .exception(Delayer::Deferred::MultipleAssignmentError, :get_child).freeze
    RESERVED
      .add(RUN, :activate)
      .add(RESERVED_C, :get_child).freeze
    RESERVED_C
      .add(RUN_C, :activate)
      .exception(Delayer::Deferred::MultipleAssignmentError, :get_child)
.freeze
    RUN
      .add(RUN_C, :get_child)
      .add(STOP, :complete).freeze
    RUN_C
      .add(CALL_CHILD, :complete)
      .exception(Delayer::Deferred::MultipleAssignmentError, :get_child)
.freeze
    CALL_CHILD
      .add(ROTTEN, :called)
    STOP
      .add(WAIT, :gaze).freeze
    WAIT
      .add(BURST_OUT, :get_child).freeze
    BURST_OUT
      .add(ROTTEN, :called).freeze

    def sequence
      @sequence ||= FRESH
    end

    def change_sequence(flow, &block)
      old_seq = sequence
      new_seq = @sequence = sequence.pull(flow)
      (@seq_logger ||= [old_seq]) << new_seq
      if block
        result = block.()
        on_sequence_changed(old_seq, flow, new_seq)
        result
      else
        on_sequence_changed(old_seq, flow, new_seq)
        nil
      end
    end

    def on_sequence_changed(old_seq, flow, new_seq)
    end

    def activated?
      ![FRESH, CONNECTED, RUN, RUN_C].include?(sequence)
    end

    def spoiled?
      sequence == ROTTEN
    end
  end
end
