# Delayer::Deferred

Delayerを使って、jsdeferredをRubyに移植したものです。
jsdeferredでできること以外に、Thread、Enumeratorを拡張します。

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
Threadには、Delayer::Deferred::Deferredableモジュールがincludeされていて、nextやtrapメソッドが使えます。

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

## Contributing

1. Fork it ( https://github.com/toshia/delayer-deferred/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
