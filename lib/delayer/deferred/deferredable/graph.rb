# -*- coding: utf-8 -*-

module Delayer::Deferred::Deferredable
=begin rdoc
graphvizによってChainableなDeferredをDOT言語形式でダンプする機能を追加するmix-in。
いずれかのノードに対して _graph_ メソッドを呼ぶと、再帰的に親子を全て辿り、digraphの断片の文字列を得ることが出来る。

== 出力例

  20892180 [shape=egg,label="#<Class:0x000000027da288>.Promise\n(reserved)"]
  20892480 [shape=box,label="test/thread_test.rb:53\n(connected)"]
  20891440 [shape=diamond,label="test/thread_test.rb:56\n(fresh)"]
  20892480 -> 20891440
  20892180 -> 20892480

=end
  module Graph
    # この一連のDeferredチェインの様子を、DOT言語フォーマットで出力する
    # ==== Args
    # [child_only:]
    #   _true_ なら、このノードとその子孫のみを描画する。
    #   _false_ なら、再帰的に親を遡り、そこから描画を開始する。
    # ==== Return
    # [String] DOT言語によるグラフ
    def graph(child_only: false)
      if child_only
        graph_child.join("\n".freeze)
      else
        ancestor.graph(child_only: true)
      end
    end

    # このノードとその子全てのDeferredチェインの様子を、DOT言語フォーマットで出力する。
    # Delayer::Deferred::Deferredable::Graph#graph の内部で利用されるため、将来このメソッドのインターフェイスは変更される可能性がある。
    # 子のみを描画したい場合は、graphメソッドの _child_only:_ 引数に _true_ を渡して利用する。
    # ==== Return
    # [Array] DOT言語によるグラフ。1行が1つの配列になっている。
    def graph_child
      if has_child?
        [ graph_mynode,
          *@child.graph_child,
          "#{__id__} -> #{@child.__id__}"
        ]
      else
        [graph_mynode]
      end
    end

    private

    # このノードを描画する時の形の名前を文字列で返す。
    # 以下のページにあるような、graphvizで取り扱える形の中から選ぶこと。
    # http://www.graphviz.org/doc/info/shapes.html
    def graph_shape
      'oval'.freeze
    end

    # このノードの形などをDOT言語の断片で返す。
    # このメソッドをオーバライドすることで、描画されるノードの見た目を自由に変更することが出来る。
    # ただし、簡単な変更だけなら別のメソッドをオーバライドするだけで可能なので、このmix-inの他のメソッドも参照すること。
    def graph_mynode
      label = "#{node_name}\n(#{sequence.name})"
      "#{__id__} [shape=#{graph_shape},label=#{label.inspect}]"
    end

  end
end
