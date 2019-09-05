defmodule BankIDTest do
  use ExUnit.Case
  doctest BankID

  test "simplified authenticate" do
    response = BankID.authenticate("127.0.0.1", "198405157879")

    assert %{
             "status" => "complete",
             "completionData" => %{
               "user" => %{
                 "personalNumber" => _,
                 "name" => _,
                 "givenName" => _,
                 "surname" => _
               },
               "device" => %{
                 "ipAddress" => _
               },
               "ocspResponse" => _,
               "signature" => _
             }
           } = response
  end

  test "simplified signing" do
    response = BankID.sign("127.0.0.1", "signing test", "198405157879")

    assert %{
             "status" => "complete",
             "completionData" => %{
               "user" => %{
                 "personalNumber" => _,
                 "name" => _,
                 "givenName" => _,
                 "surname" => _
               },
               "device" => %{
                 "ipAddress" => _
               },
               "ocspResponse" => _,
               "signature" => _
             }
           } = response
  end

  test "authentication, cancel" do
    parent = self()

    {:ok, pid} = GenServer.start_link(BankID, {:auth, parent, "127.0.0.1", "198405157879", nil})

    GenServer.cast(pid, :cancel)

    receive do
      {:response, response} ->
        assert :cancelled = response
    end
  end

  test "signing, cancel" do
    parent = self()

    {:ok, pid} =
      GenServer.start_link(
        BankID,
        {:sign, parent, "127.0.0.1", "kakor", nil, "198405157879", nil}
      )

    GenServer.cast(pid, :cancel)

    receive do
      {:response, response} ->
        assert :cancelled = response
    end
  end
end
