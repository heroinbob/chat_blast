defmodule Blaster do
  def publish_message(pid) do
    pid
    |> ChatBlast.get_status()
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

    # Start the loop over. This will spawn a
    send_messages(pid)
  end

  def publish_message(:disabled, _pid) do
    IO.puts("sending disabled.")
    :ok
  end

  defp send_messages(pid) do
    # NOTE: This is a recursive loop and run as a separate task from
    # blast_away/1. So it's protected.
    pid
    |> ChatBlast.get_delay()
    |> Process.sleep()

    publish_message(pid)
    send_messages(pid)
  end
end
