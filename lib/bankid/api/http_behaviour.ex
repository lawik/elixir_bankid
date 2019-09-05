defmodule BankID.API.HTTPBehaviour do
  @moduledoc false
  @callback make_certified_request(String.t(), String.t()) :: tuple()
end
