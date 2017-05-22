# -*- coding: utf-8 -*-
require 'delayer/deferred/error'

require 'thread'

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
        self
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
    PASS      = Sequence.new(:pass)           # パス中
    PASS_C    = Sequence.new(:pass)           # パス中
    AWAIT     = Sequence.new(:await)          # Await中
    AWAIT_C   = Sequence.new(:await)          # Await中(子がいる)
    GRAFT     = Sequence.new(:graft)          # 戻り値がAwaitableの時
    GRAFT_C   = Sequence.new(:graft)          # 戻り値がAwaitableの時(子がいる)
    CALL_CHILD= Sequence.new(:call_child)     # 完了、子がいる
    STOP      = Sequence.new(:stop)           # 完了、子なし
    WAIT      = Sequence.new(:wait)           # 完了、オブザーバ登録済み
    BURST_OUT = Sequence.new(:burst_out)      # 完了、オブザーバ登録済み、子追加済み
    ROTTEN    = Sequence.new(:rotten).freeze  # 終了
    GENOCIDE  = Sequence.new(:genocide).freeze# この地ではかつて大量虐殺があったという。

    FRESH
      .add(CONNECTED, :get_child)
      .add(RESERVED, :reserve)
      .add(GENOCIDE).freeze
    CONNECTED
      .add(RESERVED_C, :reserve)
      .exception(Delayer::Deferred::MultipleAssignmentError, :get_child)
      .add(GENOCIDE).freeze
    RESERVED
      .add(RUN, :activate)
      .add(RESERVED_C, :get_child)
      .add(GENOCIDE).freeze
    RESERVED_C
      .add(RUN_C, :activate)
      .exception(Delayer::Deferred::MultipleAssignmentError, :get_child)
      .add(GENOCIDE).freeze
    RUN
      .add(RUN_C, :get_child)
      .add(PASS)
      .add(AWAIT, :await)
      .add(STOP, :complete)
      .add(GENOCIDE).freeze
    RUN_C
      .add(PASS_C)
      .add(AWAIT_C, :await)
      .add(CALL_CHILD, :complete)
      .exception(Delayer::Deferred::MultipleAssignmentError, :get_child)
      .add(GENOCIDE).freeze
    PASS
      .add(PASS_C, :get_child)
      .add(RUN, :resume)
      .add(GENOCIDE).freeze
    PASS_C
      .add(RUN_C, :resume)
      .add(GENOCIDE).freeze
    AWAIT
      .add(RUN, :resume)
      .add(AWAIT_C, :get_child)
      .add(GENOCIDE).freeze
    AWAIT_C
      .add(RUN_C, :resume)
      .exception(Delayer::Deferred::MultipleAssignmentError, :get_child)
      .add(GENOCIDE).freeze
    CALL_CHILD
      .add(GRAFT_C, :await)
      .add(ROTTEN, :called)
      .add(GENOCIDE).freeze
    GRAFT
      .add(STOP, :resume)
      .add(GRAFT_C, :get_child)
      .add(GENOCIDE).freeze
    GRAFT_C
      .add(CALL_CHILD, :resume)
      .add(GENOCIDE).freeze
    STOP
      .add(GRAFT, :await)
      .add(WAIT, :gaze)
      .add(GENOCIDE).freeze
    WAIT
      .add(BURST_OUT, :get_child)
      .add(GENOCIDE).freeze
    BURST_OUT
      .add(ROTTEN, :called)
      .add(GENOCIDE).freeze

    SEQUENCE_LOCK = Monitor.new

    def sequence
      @sequence ||= FRESH
    end

    # このメソッドはスレッドセーフです
    def change_sequence(flow, &block)
      SEQUENCE_LOCK.synchronize do
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
    end

    def on_sequence_changed(old_seq, flow, new_seq)
    end

    def activated?
      ![FRESH, CONNECTED, RUN, RUN_C].include?(sequence)
    end

    def spoiled?
      sequence == ROTTEN || sequence == GENOCIDE
    end
  end
end
