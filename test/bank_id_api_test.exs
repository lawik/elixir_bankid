defmodule BankIDAPITest do
  use ExUnit.Case
  import Mox

  setup_all do
    Mox.defmock(BankID.HTTPMock2, for: BankID.API.HTTPBehaviour)
    Application.put_env(:bankid, :http_module, BankID.HTTPMock2)
    :ok
  end

  setup :verify_on_exit!

  @auth_response ~s({
    "autoStartToken": "mock-autostart-token",
    "orderRef": "mock-order-ref"
  })
  @sign_response ~s({
    "autoStartToken": "mock-autostart-token",
    "orderRef": "mock-order-ref"
  })
  @cancel_response ~s({})
  @collect_pending_response ~s({
    "orderRef": "mock-order-ref",
    "status": "pending",
    "hintCode": "outstandingTransaction"
  })

  @collect_success_response ~s({
    "status": "complete",
    "completionData": {
      "user": {
        "personalNumber": "198405157879",
        "name": "MockLARS MockWIKMAN",
        "givenName": "MockLARS",
        "surname": "MockWIKMAN"
      },
      "device": {
        "ipAddress": "127.0.0.1"
      },
      "ocspResponse": "mock-ocsp",
      "signature": "mock-signature"
    }
  })

  doctest BankID

  def poll_while_pending(order_ref) do
    case BankID.API.collect(order_ref) do
      %{"status" => "pending"} ->
        # :timer.sleep(2000)
        poll_while_pending(order_ref)

      response ->
        response
    end
  end

  def clean_up(order_ref) do
    on_exit(order_ref, fn ->
      BankID.HTTPMock2
      |> expect(:make_certified_request, fn _, "/cancel" -> {:ok, @cancel_response} end)

      BankID.API.cancel(order_ref)
    end)
  end

  test "auth" do
    BankID.HTTPMock2
    |> expect(:make_certified_request, fn _, "/auth" -> {:ok, @auth_response} end)

    response = BankID.API.auth("127.0.0.1", "198405157879")

    assert %{
             "autoStartToken" => _,
             "orderRef" => order_ref
           } = response

    clean_up(order_ref)
  end

  test "auth + collect" do
    BankID.HTTPMock2
    |> expect(:make_certified_request, fn _, "/auth" -> {:ok, @auth_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)

    %{"orderRef" => order_ref} = BankID.API.auth("127.0.0.1", "198405157879")

    clean_up(order_ref)

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
    BankID.HTTPMock2
    |> expect(:make_certified_request, fn _, "/auth" -> {:ok, @auth_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_success_response} end)

    personal_id_number = "198405157879"
    %{"orderRef" => order_ref} = BankID.API.auth("127.0.0.1", personal_id_number)

    clean_up(order_ref)

    # IO.puts(
    #   "Polling on auth for #{personal_id_number}. Please complete the transaction in the app."
    # )

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
    BankID.HTTPMock2
    |> expect(:make_certified_request, fn _, "/sign" -> {:ok, @sign_response} end)

    response = BankID.API.sign("127.0.0.1", "signing test", nil, "198405157879")

    assert %{
             "autoStartToken" => _,
             "orderRef" => order_ref
           } = response

    clean_up(order_ref)
  end

  test "sign + collect" do
    BankID.HTTPMock2
    |> expect(:make_certified_request, fn _, "/sign" -> {:ok, @sign_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)

    %{"orderRef" => order_ref} = BankID.API.sign("127.0.0.1", "signing test", nil, "198405157879")

    clean_up(order_ref)

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
    BankID.HTTPMock2
    |> expect(:make_certified_request, fn _, "/sign" -> {:ok, @sign_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_success_response} end)

    personal_id_number = "198405157879"
    %{"orderRef" => order_ref} = BankID.API.sign("127.0.0.1", "signing test", nil, "198405157879")

    clean_up(order_ref)

    # IO.puts(
    #   "Polling on sign for #{personal_id_number}. Please complete the transaction in the app."
    # )

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
