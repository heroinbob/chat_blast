defmodule ChatBlast do
  @moduledoc """
  Super funky fresh genserver for blasting chat messages via pubnub API.

  First, start a server. Note the required attributes being passed in here.

    {:ok, pid} = ChatBlast.start_link(%{
      publish_key: 'abc',
      rate_per_second: 5,
      subscribe_key: 'def'
    })
    {:ok, #PID<0.115.0>}

  OK, so what? well it will be configured to allow sending so when you're ready
  you'll need to start sending with the send_message function. This will start
  sending messages at the desired rate forever until you stop the server or
  you tell the server to stop sending.

  ChatBlast.blast_away(pid)
  :ok

  Now you have a separate thread looping and sending messages at the given rate.
  You can change the rate anytime.

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
  """

  use GenServer

  def blast_away(pid) do
    # Starts the long running task that sends messages at a specific rate.
    Task.start(fn -> send_messages(pid) end)
    :ok
  end

  def calculate_delay(rate_per_second) do
    ceil(1000 / rate_per_second)
  end

  def disable_sending(pid) do
    GenServer.cast(pid, :disable_sending)
  end

  def enable_sending(pid) do
    GenServer.cast(pid, :enable_sending)
  end

  def get_delay(pid) do
    GenServer.call(pid, {:get_value, :delay})
  end

  def get_rate(pid) do
    GenServer.call(pid, {:get_value, :rate_per_second})
  end

  def get_status(pid) do
    GenServer.call(pid, {:get_value, :status})
  end

  def set_rate(pid, rate_per_second) do
    GenServer.cast(pid, {:set_rate, rate_per_second})
  end

  def handle_cast(:disable_sending, current_state) do
    # Change state and affect the send message loop.
    # Returns :ok
    {:noreply, Map.put(current_state, :status, :disabled)}
  end

  def handle_cast(:enable_sending, current_state) do
    # Change state and affect the send message loop.
    # Returns :ok
    {:noreply, Map.put(current_state, :status, :enabled)}
  end

  def handle_call({:get_value, key}, _from, current_state) do
    {:reply, Map.get(current_state, key), current_state}
  end

  def handle_cast({:set_rate, rate_per_second}, current_state) do
    # Change the rate per second for future sends.
    # Returns :ok
    delay = calculate_delay(rate_per_second)

    {
      :noreply,
      Map.merge(
        current_state,
        %{
          delay: delay,
          rate_per_second: rate_per_second
        }
      )
    }
  end

  def init(options) do
    # Setup the initial state. This calculates the necessary delay and
    # sending status.
    rate = Map.get(options, :rate_per_second, 1)
    delay = calculate_delay(rate)

    {
      :ok,
      Map.merge(
        options,
        %{
          delay: delay,
          rate_per_second: rate,
          status: :enabled
        }
      )
    }
  end

  def publish_message(pid) do
    pid
    |> get_status()
    |> publish_message(pid)
  end

  def publish_message(:enabled, pid) do
    IO.puts("sending message...")

    # case PubNux.publish("channel name", "message") do
    #  {:ok, payload} ->
    #    IO.puts("Sent: #{payload}")

    #  {:error, message} ->
    #    IO.puts("Error: #{message}")

    #  {:error, message, code: code} ->
    #    IO.puts("Error: #{message} - #{code}")
    # end

    :continue
  end

  def publish_message(:disabled, _pid) do
    IO.puts("sending disabled.")
    :disabled
  end

  defp send_messages(pid) do
    # NOTE: This is a recursive loop and run as a separate task from
    # blast_away/1. So it's protected.
    pid
    |> get_delay()
    |> Process.sleep()

    if publish_message(pid) == :continue do
      send_messages(pid)
    end
  end

  def start_link(options \\ %{}) do
    # Start up the server. Returns a PID
    GenServer.start_link(__MODULE__, options)
  end
end
