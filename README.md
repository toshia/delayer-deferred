# Delayer::Deferred

Delayerの、ブロックを実行キューにキューイングする機能を利用し、エラー処理やasync/awaitのような機能をサポートするライブラリです。

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delayer-deferred'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install delayer-deferred

## Usage
### The first step
rubygemでインストールしたあと、requireします。

```ruby
require "delayer/deferred"
```

`Delayer::Deferred.new` が使えるようになります。ブロックを渡すと、Delayerのように後から(Delayer.runが呼ばれた時に)実行されます。

```ruby
Delayer.default = Delayer.generate_class  # Delayerの準備
Delayer::Deferred.new {
  p "defer"
}
Delayer.run
```

```
defer
```

`.next` メソッドで、前のブロックの実行が終わったら、その結果を受け取って次を実行することができます。

```ruby
Delayer.default = Delayer.generate_class  # Delayerの準備
Delayer::Deferred.new {
  1 + 1
}.next{ |sum|
  p sum
}
Delayer.run
```

```
2
```

### Error handling

nextブロックの中で例外が発生した場合、次のtrapブロックまで処理が飛ばされます。
trapブロックは、その例外オブジェクトを引数として受け取ります。

```ruby
Delayer.default = Delayer.generate_class  # Delayerの準備
Delayer::Deferred.new {
  1 / 0
}.next{ |sum|
  p sum
}.trap{ |exception|
  puts "Error occured!"
  p exception
}
Delayer.run
```

```
Error occured!
\#<ZeroDivisionError: divided by 0>
```

例外が発生すると、以降のnextブロックは無視され、例外が起こったブロック以降の最初のtrapブロックが実行されます。trapブロックの後にnextブロックがあればそれが実行されます。

`Delayer::Deferred.fail()` を使えば、例外以外のオブジェクトをtrapの引数に渡すこともできます。

```ruby
Delayer.default = Delayer.generate_class  # Delayerの準備
Delayer::Deferred.new {
  Delayer::Deferred.fail("test error message")
}.trap{ |exception|
  puts "Error occured!"
  p exception
}
Delayer.run
```

```
Error occured!
"test error message"
```

### Thread
Threadには、nextやtrapメソッドが実装されているので、Deferredのように扱うことができます。

```ruby
Delayer.default = Delayer.generate_class  # Delayerの準備
Thread.new {
  1 + 1
}.next{ |sum|
  p sum
}
Delayer.run
```

```
2
```

この場合、nextやtrapのブロックは、全て `Delayer.run` メソッドが実行された側のThreadで実行されます。

### Automatically Divide a Long Loop
`Enumerable#deach`, `Enumerator#deach`はeachの変種で、Delayerのexpireの値よりループに時間がかかったら一旦処理を中断して、続きを実行するDeferredを新たに作ります。

```ruby
complete = false
Delayer.default = Delayer.generate_class(expire: 0.1)  # Delayerの準備
(1..100000).deach{ |digit|
  p digit
}.next{
  puts "complete"
  complete = true
}.trap{ |exception|
  p exception
  complete = true
}
while !complete
  Delayer.run
  puts "divided"
end
```

```
1
2
3
(中略)
25398
divided
25399
(中略)
100000
complete
divided
```

開発している環境では、25398までループした後、0.1秒経過したので一度処理が分断され、Delayer.runから処理が帰ってきています。

また、このメソッドはDeferredを返すので、ループが終わった後に処理をしたり、エラーを受け取ったりできます。

### Pass to another Delayer

Deferredのコンテキストの中で `Deferred.pass` を呼ぶと、そこで一旦処理が中断し、キューの最後に並び直します。
他のDelayerが処理され終わると `Deferred.pass` から処理が戻ってきて、再度そこから実行が再開されます。

`Deferred.pass` は常に処理を中断するわけではなく、Delayerの時間制限を過ぎている場合にのみ処理をブレークします。
用途としては `Enumerator#deach` が使えないようなループの中で毎回呼び出して、長時間処理をブロックしないようにするといった用途が考えられます。

`Enumerator#deach` は `Deferred.pass` を用いて作られています。

### Combine Deferred

`Deferred.when` は、引数に2つ以上のDeferredを受け取り、新たなDeferredを一つ返します。

引数のDeferredすべてが正常に終了したら、戻り値のDeferredのnextブロックが呼ばれ、whenの引数の順番通りに戻り値が渡されます。
複数のDeferredがあって、それらすべてが終了するのを待ち合わせる時に使うと良いでしょう。

```ruby
web_a = Thread.new{ open("http://example.com/a.html") }
web_b = Thread.new{ open("http://example.com/b.html") }
web_c = Thread.new{ open("http://example.com/c.html") }

# 引数の順番は対応している
Deferred.when(web_a, web_b, web_c).next do |a, b, c|
  ...
end

# 配列を渡すことも出来る
Deferred.when([web_a, web_b, web_c]).next do |a, b, c|
  ...
end

```

引数のDeferredのうち、どれか一つでも失敗すると、直ちに `Deferred.when` の戻り値のtrapブロックが呼ばれます。trapの引数は、失敗したDeferredのそれです。

どれか一つでも失敗すると、他のDeferredが成功していたとしてもその結果は破棄されるということに気をつけてください。より細かく制御したい場合は、Async/Awaitを利用しましょう。

```ruby
divzero = Delayer::Deferred.new {
  1 / 0
}
web_a = Thread.new{ open("http://example.com/a.html") }

Deferred.when(divzero, web_a).next{
  puts 'success'
}.trap{|err|
  p err
}
```

```
\#<ZeroDivisionError: divided by 0>
```

### Async/Await

Deferred#next や Deferred#trap のブロック内では、Deferredable#+@ が使えます。非同期な処理を同期処理のように書くことができます。

+@を呼び出すと、呼び出し元のDeferredの処理が一時停止し、+@のレシーバになっているDeferredableが完了した後に処理が再開されます。また、戻り値はレシーバのDeferredableのそれになります。

```
request = Thread.new{ open("http://mikutter.hachune.net/download/unstable.json").read }
Deferred.next{
  puts "最新の不安定版mikutterのバージョンは"
  response = JSON.parse(+request)
  puts response.first["version_string"]
  puts "です"
}
```

`+request` が呼ばれた時、リクエスト完了まで処理は一時止まりますが、他にDelayerキューにジョブが溜まっていたら、そちらが実行されます。この機能を使わない場合は、HTTPレスポンスを受け取るまでDelayerの他のジョブは停止してしまいます。

## Contributing

1. Fork it ( https://github.com/toshia/delayer-deferred/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
