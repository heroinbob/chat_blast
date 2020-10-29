# ChatBlast

## How To Use
```
# Start up an iex session
iex -S mix

# Start up a server...
{:ok, pid} = ChatBlast.start_link(%{
  pubnub_config: [
    channel: 'test',
    pub_key: 'abc',
    sub_key: '123',
  ],
  rate_per_second: 5,
})

# Start sending
ChatBlast.blast_away(pid)
```

The pid is your link to the running process. Now you can change rates and pause on the fly.

```
# Set to 10/second
ChatBlast.set_rate(pid, 10)
:ok

You can also stop the send loop.

ChatBlast.disable_sending(pid)
:ok

Now the loop will pick up on the new status and the thread will end. To start
up again you can enable sending and start the process over.

ChatBlast.enable_sending(pid)
:ok
ChatBlast.blast_away(pid)
:ok
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `chat_blast` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chat_blast, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/chat_blast](https://hexdocs.pm/chat_blast).

