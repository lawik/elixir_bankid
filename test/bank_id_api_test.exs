defmodule BankIDAPITest do
  use ExUnit.Case
  doctest BankID

  def poll_while_pending(order_ref) do
    case BankID.API.collect(order_ref) do
      %{"status" => "pending"} ->
        :timer.sleep(2000)
        poll_while_pending(order_ref)

      response ->
        response
    end
  end

  test "auth" do
    response = BankID.API.auth("127.0.0.1", "198405157879")

    assert %{
             "autoStartToken" => _,
             "orderRef" => order_ref
           } = response

    on_exit(order_ref, fn ->
      BankID.API.cancel(order_ref)
    end)
  end

  test "auth + collect" do
    %{"orderRef" => order_ref} = BankID.API.auth("127.0.0.1", "198405157879")

    on_exit(order_ref, fn ->
      BankID.API.cancel(order_ref)
    end)

    # We do it twice to pretend to be polling ;)
    response = BankID.API.collect(order_ref)

    assert %{
             "orderRef" => _,
             "status" => "pending",
             "hintCode" => _
           } = response

    response = BankID.API.collect(order_ref)

    assert %{
             "orderRef" => _,
             "status" => "pending",
             "hintCode" => _
           } = response
  end

  test "auth + collect - polling until success" do
    personal_id_number = "198405157879"
    %{"orderRef" => order_ref} = BankID.API.auth("127.0.0.1", personal_id_number)

    on_exit(order_ref, fn ->
      BankID.API.cancel(order_ref)
    end)

    IO.puts(
      "Polling on auth for #{personal_id_number}. Please complete the transaction in the app."
    )

    response = poll_while_pending(order_ref)

    assert %{
             "status" => "complete",
             "completionData" => %{
               "user" => %{
                 "personalNumber" => ^personal_id_number,
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

  test "sign" do
    response = BankID.API.sign("127.0.0.1", "signing test", nil, "198405157879")

    assert %{
             "autoStartToken" => _,
             "orderRef" => order_ref
           } = response

    on_exit(order_ref, fn ->
      BankID.API.cancel(order_ref)
    end)
  end

  test "sign + collect" do
    %{"orderRef" => order_ref} = BankID.API.sign("127.0.0.1", "signing test", nil, "198405157879")

    on_exit(order_ref, fn ->
      BankID.API.cancel(order_ref)
    end)

    # We do it twice to pretend to be polling ;)
    response = BankID.API.collect(order_ref)

    assert %{
             "orderRef" => _,
             "status" => "pending",
             "hintCode" => _
           } = response

    response = BankID.API.collect(order_ref)

    assert %{
             "orderRef" => _,
             "status" => "pending",
             "hintCode" => _
           } = response
  end

  test "sign + collect - polling until success" do
    personal_id_number = "198405157879"
    %{"orderRef" => order_ref} = BankID.API.sign("127.0.0.1", "signing test", nil, "198405157879")

    on_exit(order_ref, fn ->
      BankID.API.cancel(order_ref)
    end)

    IO.puts(
      "Polling on sign for #{personal_id_number}. Please complete the transaction in the app."
    )

    response = poll_while_pending(order_ref)

    assert %{
             "status" => "complete",
             "completionData" => %{
               "user" => %{
                 "personalNumber" => ^personal_id_number,
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
end
