defmodule BankID.API do
  @moduledoc """
  Documentation for BankID.
  """

  alias BankID.Requests

  def http_module, do: Application.get_env(:bankid, :http_module)

  def auth(end_user_ip, personal_number \\ nil, requirement \\ nil) do
    Requests.encode_auth(end_user_ip, personal_number, requirement)
    |> http_module().make_certified_request("/auth")
    |> check_ok()
    |> Requests.decode_auth()
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
    |> http_module().make_certified_request("/sign")
    |> check_ok()
    |> Requests.decode_sign()
  end

  def cancel(order_ref) do
    Requests.encode_cancel(order_ref)
    |> http_module().make_certified_request("/cancel")
    |> check_ok_or_error()
    |> Requests.decode_cancel()
  end

  def collect(order_ref) do
    Requests.encode_collect(order_ref)
    |> http_module().make_certified_request("/collect")
    |> check_ok_or_error()
    |> Requests.decode_collect()
  end

  defp check_ok({:ok, response}) do
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
end
