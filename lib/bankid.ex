defmodule BankID do
  use GenServer

  # 2 seconds
  @poll_time 2000

  # Stupid simple authentication, non-interactive, blocking
  def authenticate(end_user_ip, personal_number, requirement \\ nil) do
    parent = self()

    {:ok, _pid} =
      GenServer.start_link(BankID, {:auth, parent, end_user_ip, personal_number, requirement})

    receive do
      {:response, response} ->
        response
    end
  end

  # Stupid simple signing, non-interactive, blocking
  def sign(
        end_user_ip,
        user_visible_data,
        personal_number,
        user_non_visible_data \\ nil,
        requirement \\ nil
      ) do
    parent = self()

    {:ok, _pid} =
      GenServer.start_link(
        BankID,
        {:sign, parent, end_user_ip, user_visible_data, user_non_visible_data, personal_number,
         requirement}
      )

    receive do
      {:response, response} ->
        response
    end
  end

  @impl true
  def handle_cast(:cancel, {_, parent, order_reference, _}) do
    response = BankID.API.cancel(order_reference)
    Process.send(parent, {:response, :cancelled}, [])
    {:stop, :normal, {:done, parent, nil, response}}
  end

  @impl true
  def init({:auth, parent, end_user_ip, personal_number, requirement}) do
    %{"orderRef" => order_reference} = BankID.API.auth(end_user_ip, personal_number, requirement)
    schedule_polling()
    {:ok, {:pending, parent, order_reference, nil}}
  end

  @impl true
  def init(
        {:sign, parent, end_user_ip, user_visible_data, user_non_visible_data, personal_number,
         requirement}
      ) do
    %{"orderRef" => order_reference} =
      BankID.API.sign(
        end_user_ip,
        user_visible_data,
        user_non_visible_data,
        personal_number,
        requirement
      )

    schedule_polling()
    {:ok, {:pending, parent, order_reference, nil}}
  end

  @impl true
  def handle_info(:poll, {_, parent, order_reference, _} = state) do
    case BankID.API.collect(order_reference) do
      %{"status" => "pending"} ->
        schedule_polling()
        {:noreply, state}

      response ->
        Process.send(parent, {:response, response}, [])
        {:stop, :normal, {:done, parent, nil, response}}
    end
  end

  defp schedule_polling() do
    Process.send_after(self(), :poll, @poll_time)
  end
end
