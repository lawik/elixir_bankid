defmodule BankID.API.HTTP do
  @behaviour BankID.API.HTTPBehaviour

  @test_url 'https://appapi2.test.bankid.com/rp/v5'
  @production_url 'https://appapi2.bankid.com/rp/v5'

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
    ]

    http_options = [{:ssl, ssl_options}]
    url = base_url ++ to_charlist(path)
    request = {url, [], 'application/json', String.to_charlist(data)}

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
