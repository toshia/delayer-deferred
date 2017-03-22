# -*- coding: utf-8 -*-

module Delayer::Deferred::Deferredable
  module NodeSequence
    class Sequence
      attr_reader :name

      def initialize(name)
        @name = name.to_sym
        @map = {}
      end

      def add(seq, seq_name = seq.name)
        @map[seq_name] = seq
        self
      end

      def pull(seq)
        if @map.has_key?(seq.to_sym)
          @map[seq.to_sym]
        else
          raise Delayer::Deferred::SequenceError, "Invalid sequence flow `#{name}' to `#{seq}'."
        end
      end

      def inspect
        "#<#{self.class}: #{name}>"
      end
    end

    FRESH     = Sequence.new(:fresh)
    CONNECTED = Sequence.new(:connected)      # 子がいる、未実行
    RUN       = Sequence.new(:run)            # 実行中
    RUN_WITH  = Sequence.new(:run_with_child) # 実行中(子がいる)
    WAIT      = Sequence.new(:wait)           # 完了、子なし
    ROTTEN    = Sequence.new(:rotten).freeze  # 終了

    FRESH
      .add(CONNECTED, :get_child)
      .add(RUN, :activate).freeze
    CONNECTED
      .add(RUN_WITH, :activate).freeze
    RUN
      .add(RUN_WITH, :get_child)
      .add(WAIT, :complete).freeze
    RUN_WITH
      .add(ROTTEN, :complete).freeze
    WAIT
      .add(ROTTEN, :get_child).freeze

    def sequence
      @sequence ||= FRESH
    end

    def change_sequence(seq_name)
      @sequence = sequence.pull(seq_name)
    end

    def spoiled?
      sequence == ROTTEN
    end
  end
end
