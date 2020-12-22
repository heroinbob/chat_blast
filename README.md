# ChatBlast

## How To Use
First you'll want to create `pubnub.config` which is a json file that contains
`pub_key` and `sub_key` respectively. This is used to build the correct URL
to send messages.

```
# Start up an iex session
iex -S mix

# Start up a server. This defaults to 1 msg/s. You can include rate_per_second
# in this if you want to start at another rate.
{:ok, pid} = ChatBlast.start_link(%{channel: 'test'})

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

