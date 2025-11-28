# Red FlatBuffers

Red FlatBuffers is a pure Ruby FlatBuffers implementation.

Red FlatBuffers can generate Ruby code that reads and writes (not implemented yet) FlatBuffers from `.fbfs` (binary FlatBuffers schema). Red FlatBuffers can't compile `.fbs` (FlatBuffers schema) to `.fbfs`. You need to use FlatBuffers to compile `.fbs` to `.bfbs`.

## Install

```bash
gem install red-flatbuffers
```

## Usage

### Generate Ruby code

Generate `.bfbs` from `.fbs` by `flatc` that is provided by https://github.com/google/flatbuffers/ :

```bash
flatc \
  --binary \
  --schema \
  --bfbs-builtins \
  --bfbs-comments \
  YOUR_SCHEMA.fbs
```

The order of arguments is important. You must specify `--bfbs-builtins` and `--bfbs-comments` AFTER `--binary`. If you specify them BEFORE `--binary`, they are ignored.

Generate Ruby code from `.bfbs`:

```bash
rbflatc YOUR_SCHEMA.bfbs
```

It generates Ruby code in the current directory. You can change it by `--output-dir`:

```bash
rbflatc --output-dir lib YOUR_SCHEMA.bfbs
```

If you want to wrap generate code by namespaces, you can use `--outer-namespaces`:

```bash
rbflatc \
  --output-dir lib/my/namespace \
  --outer-namespaces My::Namespace \
  YOUR_SCHEMA.bfbs
```

### Read FlatBuffers data by generated Ruby code

If you want to read FlatBuffers data in a file, you can use `File.open` and `IO::Buffer.map`:

```ruby
require "my/schema"

File.open("data.fbs", "rb") do |input|
  buffer = IO::Buffer.map(input, nil, 0, IO::Buffer::READONLY)
  schema = My::Schema.new(buffer)
  # Use schema
end
```

If you have FlatBuffers data as `String`, you can just pass it to your generated Ruby code:

```ruby
require "my/schema"

schema = My::Schema.new(data)
# Use schema
```

### Writer FlatBuffers data by generated Ruby code

This is not implemented yet.

## Authors

* Sutou Kouhei \<kou@clear-code.com\>

## License

Apache License 2.0. See doc/text/apache-2.0.txt for details.
