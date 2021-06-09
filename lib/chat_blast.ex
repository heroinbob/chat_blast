defmodule ChatBlast do
  @moduledoc """
  Super funky fresh genserver for blasting chat messages via pubnub API.

  First, start a server. Note the required attributes being passed in here.

    {:ok, pid} = ChatBlast.start_link(%{channel: 'test'})
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

  @artist :artist
  @fan :fan

  use GenServer

  def blast_away(pid) do
    HTTPoison.start()

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

  def get_channel(pid) do
    GenServer.call(pid, {:get_value, :channel})
  end

  def get_delay(pid) do
    GenServer.call(pid, {:get_value, :delay})
  end

  def get_pubnub_pub_key(pid) do
    GenServer.call(pid, {:get_value, :pubnub_pub_key})
  end

  def get_pubnub_sub_key(pid) do
    GenServer.call(pid, {:get_value, :pubnub_sub_key})
  end

  def get_rate(pid) do
    GenServer.call(pid, {:get_value, :rate_per_second})
  end

  def get_status(pid) do
    GenServer.call(pid, {:get_value, :status})
  end

  def get_sent_count(pid) do
    GenServer.call(pid, {:get_value, :sent_count})
  end

  def inc_sent_count(pid) do
    GenServer.cast(pid, :inc_sent_count)
  end

  def set_channel(pid, channel) do
    GenServer.cast(pid, {:set_channel, channel})
  end

  def set_rate(pid, rate_per_second) do
    GenServer.cast(pid, {:set_rate, rate_per_second})
  end

  def handle_call({:get_value, key}, _from, current_state) do
    {:reply, Map.get(current_state, key), current_state}
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

  def handle_cast(:inc_sent_count, current_state) do
    sent_count = Map.get(current_state, :sent_count)

    {:noreply, Map.put(current_state, :sent_count, sent_count + 1)}
  end

  def handle_cast({:set_channel, channel}, current_state) do
    {:noreply, Map.put(current_state, :channel, channel)}
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
    Faker.start()

    pubnub_config = load_pubnub_config()

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
          pubnub_pub_key: Map.get(pubnub_config, "pub_key"),
          pubnub_sub_key: Map.get(pubnub_config, "sub_key"),
          rate_per_second: rate,
          sent_count: 0,
          status: :enabled
        }
      )
    }
  end

  def load_pubnub_config do
    dir = File.cwd!()
    content = File.read!("#{dir}/pubnub.config")

    JSON.decode!(content)
  end

  def publish_message(:enabled, pid, message, user_type) do
    {:ok, body} =
      JSON.encode(
        avatar: nil,
        author: "Blast McGee",
        body: "#{message} #{get_sent_count(pid)}",
        cuid: "chatblast-user",
        type: user_type
      )

    headers = ["Content-Type": "application/json"]

    case HTTPoison.post(pubnub_url(pid), body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        inc_sent_count(pid)
        IO.puts("sent!")

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        IO.puts("Failed to send: #{status_code}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Failed to send: #{reason}")
    end
  end

  def publish_message(:disabled, _pid, _message, _user_type) do
    IO.puts("sending disabled.")
  end

  def pubnub_url(pid) do
    channel = get_channel(pid)
    pub_key = get_pubnub_pub_key(pid)
    sub_key = get_pubnub_sub_key(pid)

    "https://ps.pndsn.com/publish/#{pub_key}/#{sub_key}/0/#{channel}/doNothingCallback?uuid=chatblast-user-123"
  end

  # Send a message as the artist. This ignores enabled/disabled status.
  def send_artist_message(pid, message \\ Faker.Lorem.sentence()) do
    publish_message(
      :enabled,
      pid,
      message,
      @artist
    )
  end

  def send_banned_message(pid, channel) do
    pub_key = get_pubnub_pub_key(pid)
    sub_key = get_pubnub_sub_key(pid)

    url =
      "https://ps.pndsn.com/publish/#{pub_key}/#{sub_key}/0/#{channel}/doNothingCallback?uuid=chatblast-user-123"

    {:ok, body} = JSON.encode(publishable: false)

    headers = ["Content-Type": "application/json"]

    case HTTPoison.post(pubnub_url(pid), body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        IO.puts("sent!")

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        IO.puts("Failed to send: #{status_code}")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.puts("Failed to send: #{reason}")
    end
  end

  # Send a message as a fan. This adheres to the enabled/disable status.
  def send_fan_message(pid, message \\ Faker.Lorem.sentence()) do
    pid
    |> get_status()
    |> publish_message(pid, message, @fan)
  end

  defp send_messages(pid) do
    # NOTE: This is a recursive loop and run as a separate task from
    # blast_away/1. So it's protected.
    pid
    |> get_delay()
    |> Process.sleep()

    Task.start(fn -> send_fan_message(pid) end)

    if get_status(pid) == :enabled do
      send_messages(pid)
    end
  end

  def start_link(options \\ %{}) do
    # Start up the server. Returns a PID
    GenServer.start_link(__MODULE__, options)
  end
end
