defmodule BankID.Requests do
  @user_visible_data_limit 40_000
  @user_non_visible_data_limit 200_000

  def encode_auth(end_user_ip, personal_number \\ nil, requirement \\ nil) do
    request =
      case {is_nil(personal_number), is_nil(requirement)} do
        {true, true} ->
          %{
            "endUserIp" => end_user_ip
          }

        {false, true} ->
          %{
            "endUserIp" => end_user_ip,
            "personalNumber" => personal_number
          }

        {true, false} ->
          %{
            "endUserIp" => end_user_ip,
            "requirement" => requirement
          }

        {false, false} ->
          %{
            "endUserIp" => end_user_ip,
            "personalNumber" => personal_number,
            "requirement" => requirement
          }
      end

    Jason.encode!(request)
  end

  def decode_auth(response) do
    Jason.decode!(response)
  end

  def encode_sign(
        end_user_ip,
        user_visible_data,
        user_non_visible_data \\ nil,
        personal_number \\ nil,
        requirement \\ nil
      ) do
    user_visible_data_encoded = Base.encode64(user_visible_data)

    if String.length(user_visible_data_encoded) < 1 do
      raise("user_visible_data_too_short")
    end

    if String.length(user_visible_data_encoded) > @user_visible_data_limit do
      raise("user_visible_data_limit_exceeded")
    end

    request = %{
      "endUserIp" => end_user_ip,
      "userVisibleData" => user_visible_data_encoded
    }

    request =
      case user_non_visible_data do
        nil ->
          request

        _ ->
          user_non_visible_data_encoded = Base.encode64(user_non_visible_data)

          if String.length(user_visible_data_encoded) > @user_non_visible_data_limit do
            raise("user_non_visible_data_limit_exceeded")
          end

          Map.put_new(request, "userNonVisibleData", user_non_visible_data_encoded)
      end

    request =
      case personal_number do
        nil ->
          request

        _ ->
          Map.put_new(request, "personalNumber", personal_number)
      end

    request =
      case requirement do
        nil ->
          request

        _ ->
          Map.put_new(request, "requirement", requirement)
      end

    Jason.encode!(request)
  end

  def decode_sign(response) do
    Jason.decode!(response)
  end

  def encode_cancel(order_ref) do
    request = %{"orderRef" => order_ref}

    Jason.encode!(request)
  end

  def decode_cancel(response) do
    Jason.decode!(response)
  end

  def encode_collect(order_ref) do
    request = %{"orderRef" => order_ref}

    Jason.encode!(request)
  end

  def decode_collect(response) do
    Jason.decode!(response)
  end
end
