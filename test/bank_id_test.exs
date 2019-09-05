defmodule BankIDTest do
  use ExUnit.Case
  import Mox

  setup_all do
    Mox.defmock(BankID.HTTPMock, for: BankID.API.HTTPBehaviour)
    Application.put_env(:bankid, :http_module, BankID.HTTPMock)
    :ok
  end

  setup :set_mox_global
  setup :verify_on_exit!

  doctest BankID

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

  test "simplified authenticate" do
    BankID.HTTPMock
    |> expect(:make_certified_request, fn _, "/auth" -> {:ok, @auth_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_success_response} end)

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
    BankID.HTTPMock
    |> expect(:make_certified_request, fn _, "/sign" -> {:ok, @sign_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)
    |> expect(:make_certified_request, fn _, "/collect" -> {:ok, @collect_success_response} end)

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
    BankID.HTTPMock
    |> expect(:make_certified_request, fn _, "/auth" -> {:ok, @auth_response} end)
    |> expect(:make_certified_request, fn _, "/cancel" -> {:ok, @cancel_response} end)
    |> stub(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)

    parent = self()

    {:ok, pid} = GenServer.start_link(BankID, {:auth, parent, "127.0.0.1", "198405157879", nil})

    GenServer.cast(pid, :cancel)

    receive do
      {:response, response} ->
        assert :cancelled = response
    end
  end

  test "signing, cancel" do
    BankID.HTTPMock
    |> expect(:make_certified_request, fn _, "/sign" -> {:ok, @sign_response} end)
    |> expect(:make_certified_request, fn _, "/cancel" -> {:ok, @cancel_response} end)
    |> stub(:make_certified_request, fn _, "/collect" -> {:ok, @collect_pending_response} end)

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
