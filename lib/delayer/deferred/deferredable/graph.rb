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
    # [output:]
    #   このオブジェクトに、 _<<_ メソッドで内容が書かれる。
    #   省略した場合は、戻り値が _String_ になる。
    # ==== Return
    # [String] DOT言語によるグラフ
    # [output:] 引数 output: に指定されたオブジェクト
    def graph(child_only: false, output: String.new)
      if child_only
        output << "digraph Deferred {\n".freeze
        Enumerator.new{ |yielder|
          graph_child(output: yielder)
        }.lazy.each{|l|
          output << "\t#{l}\n"
        }
        output << '}'.freeze
      else
        ancestor.graph(child_only: true, output: output)
      end
    end

    # Graph.graph の結果を内容とする一時ファイルを作成して返す。
    # ただし、ブロックを渡された場合は、一時ファイルを引数にそのブロックを一度だけ実行し、ブロックの戻り値をこのメソッドの戻り値とする。
    # ==== Args
    # [&block] 一時ファイルを利用する処理
    # ==== Return
    # [Tempfile] ブロックを指定しなかった場合。作成された一時ファイルオブジェクト
    # [Object] ブロックが指定された場合。ブロックの実行結果。
    def graph_save(permanent: false, &block)
      if block
        Tempfile.open{|tmp|
          graph(output: tmp)
          tmp.seek(0)
          block.(tmp)
        }
      else
        tmp = Tempfile.open
        graph(output: tmp).tap{|t|t.seek(0)}
      end
    end

    # 画像ファイルとしてグラフを書き出す。
    # dotコマンドが使えないと失敗する。
    # ==== Args
    # [format:] 画像の拡張子
    # ==== Return
    # [String] 書き出したファイル名
    def graph_draw(dir: '/tmp', format: 'svg'.freeze)
      graph_save do |dotfile|
        base = File.basename(dotfile.path)
        dest = File.join(dir, "#{base}.#{format}")
        system("dot -T#{format} #{dotfile.path} -o #{dest}")
        dest
      end
    end

    # このノードとその子全てのDeferredチェインの様子を、DOT言語フォーマットで出力する。
    # Delayer::Deferred::Deferredable::Graph#graph の内部で利用されるため、将来このメソッドのインターフェイスは変更される可能性がある。
    def graph_child(output:)
      output << graph_mynode
      if has_child?
        @child.graph_child(output: output)
        output << "#{__id__} -> #{@child.__id__}"
      end
      if has_awaited?
        awaited.each do |awaitable|
          if awaitable.is_a?(Delayer::Deferred::Deferredable::Chainable)
            awaitable.ancestor.graph_child(output: output)
          else
            label = "#{awaitable.class}"
            output << "#{awaitable.__id__} [shape=oval,label=#{label.inspect}]"
          end
          output << "#{awaitable.__id__} -> #{__id__} [label = \"await\", style = \"dotted\"]"
        end
      end
      nil
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
