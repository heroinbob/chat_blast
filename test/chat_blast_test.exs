defmodule ChatBlastTest do
  use ExUnit.Case
  doctest ChatBlast

  test "greets the world" do
    assert ChatBlast.hello() == :world
  end
end
