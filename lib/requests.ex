defmodule BankID.Requests do
  def encode_auth(end_user_ip, personal_number \\ nil, requirement \\ nil) do
    request =
      case {is_nil(personal_number), is_nil(requirement)} do
        {true, true} ->
          %{
            endUserIp: end_user_ip
          }

        {false, true} ->
          %{
            endUserIp: end_user_ip,
            personalNumber: personal_number
          }

        {true, false} ->
          %{
            endUserIp: end_user_ip,
            requirement: requirement
          }

        {false, false} ->
          %{
            endUserIp: end_user_ip,
            personalNumber: personal_number,
            requirement: requirement
          }
      end

    to_charlist(Jason.encode!(request))
  end

  def decode_auth(response) do
    Jason.decode!(response)
  end
end
