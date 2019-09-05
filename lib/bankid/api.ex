defmodule BankID.API do
  @moduledoc """
  Documentation for BankID.
  """

  alias BankID.Requests

  @test_url 'https://appapi2.test.bankid.com/rp/v5'
  @production_url 'https://appapi2.bankid.com/rp/v5'

  def auth(end_user_ip, personal_number \\ nil, requirement \\ nil) do
    Requests.encode_auth(end_user_ip, personal_number, requirement)
    |> make_certified_request("/auth")
    |> check_ok()
    |> Requests.decode_auth()
    |> IO.inspect()
  end

  def sign(
        end_user_ip,
        user_visible_data,
        user_non_visible_data \\ nil,
        personal_number \\ nil,
        requirement \\ nil
      ) do
    Requests.encode_sign(
      end_user_ip,
      user_visible_data,
      user_non_visible_data,
      personal_number,
      requirement
    )
    |> make_certified_request("/sign")
    |> check_ok()
    |> Requests.decode_sign()
    |> IO.inspect()
  end

  def cancel(order_ref) do
    Requests.encode_cancel(order_ref)
    |> make_certified_request("/cancel")
    |> check_ok_or_error()
    |> Requests.decode_cancel()
    |> IO.inspect()
  end

  def collect(order_ref) do
    Requests.encode_collect(order_ref)
    |> make_certified_request("/collect")
    |> check_ok_or_error()
    |> Requests.decode_collect()
    |> IO.inspect()
  end

  defp check_ok({:ok, response}) do
    IO.inspect(response)
    response
  end

  defp check_ok({:error, response}) do
    {:ok, {{'HTTP/1.1', status_code, _}, _headers, response_body}} = response

    raise "Received #{status_code} in check_ok. Response: #{response_body}"
  end

  defp check_ok_or_error(raw_response) do
    case raw_response do
      {:ok, body} ->
        body

      {:error, response} ->
        {:ok, {{'HTTP/1.1', _status_code, _}, _headers, body}} = response
        body
    end
  end

  def make_certified_request(data, path) do
    environment = Application.get_env(:bankid, :environment, :production)

    base_url =
      case environment do
        :production -> @production_url
        :test -> @test_url
      end

    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    ssl_options = [
      {:cacertfile, '/Users/lawik/projects/bankid/ca_cert.cer'},
      {:certfile, '/Users/lawik/projects/bankid/ssl_cert.pem'}
      # {:versions, ['tlsv1.2']}
    ]

    http_options = [{:ssl, ssl_options}]
    url = base_url ++ to_charlist(path)
    IO.puts(url)
    # request_body = '{"endUserIp"}'

    # {:ok, {{'HTTP/1.1', status_code, _}, _headers, response_body}}
    request = {url, [], 'application/json', data}
    IO.inspect(request)

    {:ok, {{'HTTP/1.1', status_code, _}, _headers, response_body}} =
      response =
      :httpc.request(
        :post,
        request,
        http_options,
        []
      )

    case status_code do
      200 -> {:ok, response_body}
      _ -> {:error, response}
    end
  end
end
