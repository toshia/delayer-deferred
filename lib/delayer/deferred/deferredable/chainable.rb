# -*- coding: utf-8 -*-
require "delayer/deferred/deferredable/awaitable"
require "delayer/deferred/deferredable/graph"
require "delayer/deferred/deferredable/node_sequence"

module Delayer::Deferred::Deferredable
  module Chainable
    include Awaitable
    include Graph
    include NodeSequence

    attr_reader :child

    # このDeferredが成功した場合の処理を追加する。
    # 新しいDeferredのインスタンスを返す。
    # このメソッドはスレッドセーフです。
    # TODO: procが空のとき例外を発生させる
    def next(&proc)
      add_child(Delayer::Deferred::Chain::Next.new(&proc))
    end
    alias deferred next

    # このDeferredが失敗した場合の処理を追加する。
    # 新しいDeferredのインスタンスを返す。
    # このメソッドはスレッドセーフです。
    # TODO: procが空のとき例外を発生させる
    def trap(&proc)
      add_child(Delayer::Deferred::Chain::Trap.new(&proc))
    end
    alias error trap

    # この一連のDeferredをこれ以上実行しない。
    # このメソッドはスレッドセーフです。
    def cancel
      change_sequence(:genocide) unless spoiled?
    end

    def has_child?
      child ? true : false
    end

    # 子を追加する。
    # _Delayer::Deferred::Chainable_ を直接指定できる。通常外部から呼ぶときは _next_ か _trap_ メソッドを使うこと。
    # このメソッドはスレッドセーフです。
    # ==== Args
    # [chainable] 子となるDeferred
    # ==== Return
    # 必ず _chainable_ を返す
    # ==== Raise
    # [Delayer::Deferred::SequenceError]
    #   既に子が存在している場合
    def add_child(chainable)
      change_sequence(:get_child) do
        chainable.parent = self
        @child = chainable
      end
    end

    # 子が追加された時に一度だけコールバックするオブジェクトを登録する。
    # observerと言っているが、実際には _Delayer::Deferred::Worker_ を渡して利用している。
    # このメソッドはスレッドセーフです。
    # ==== Args
    # [observer] pushメソッドを備えているもの。引数に _@child_ の値が渡される
    # ==== Return
    # self
    def add_child_observer(observer)
      change_sequence(:gaze) do
        @child_observer = observer
      end
      self
    end

    def awaited
      @awaited ||= [].freeze
    end

    def has_awaited?
      not awaited.empty?
    end

    def add_awaited(awaitable)
      @awaited = [*awaited, awaitable].freeze
      self
    end

    # activateメソッドを呼ぶDelayerジョブを登録する寸前に呼ばれる。
    def reserve_activate
      change_sequence(:reserve)
    end

    def enter_pass
      change_sequence(:pass)
    end

    def exit_pass
      change_sequence(:resume)
    end

    protected

    # 親を再帰的に辿り、一番最初のノードを返す。
    # 親が複数見つかった場合は、それらを返す。
    def ancestor
      if @parent
        @parent.ancestor
      else
        self
      end
    end

    # cancelとかデバッグ用のコールグラフを得るために親を登録しておく。
    # add_childから呼ばれる。
    def parent=(chainable)
      @parent = chainable
    end

    private

    def call_child_observer
      if has_child? and defined?(@child_observer)
        change_sequence(:called)
        @child_observer.push(@child)
      end
    end

    def on_sequence_changed(old_seq, flow, new_seq)
      case new_seq
      when NodeSequence::BURST_OUT
        call_child_observer
      when NodeSequence::GENOCIDE
        @parent.cancel if defined?(@parent) and @parent
      when NodeSequence::RESERVED_C, NodeSequence::RUN_C, NodeSequence::PASS_C, NodeSequence::AWAIT_C, NodeSequence::GRAFT_C
        if !has_child?
          notice "child: #{@child.inspect}"
          raise Delayer::Deferred::SequenceError.new("Sequence changed `#{old_seq.name}' to `#{flow}', but it has no child")
        end
      end
    end

    # ノードの名前。サブクラスでオーバライドし、ノードが定義されたファイルの名前や行数などを入れておく。
    def node_name
      self.class.to_s
    end

    def graph_mynode
      if defined?(@seq_logger)
        label = "#{node_name}\n(#{@seq_logger.map(&:name).join('→')})"
      else
        label = "#{node_name}\n(#{sequence.name})"
      end
      "#{__id__} [shape=#{graph_shape},label=#{label.inspect}]"
    end

  end
end
