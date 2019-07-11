defmodule BankIDTest do
  use ExUnit.Case
  doctest BankID

  test "auth" do
    response = BankID.auth("127.0.0.1", "198405157879")

    IO.inspect(response)
  end
end
