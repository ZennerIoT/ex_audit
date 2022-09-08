defmodule ExAudit.Tracking.AdditionalData do
  @moduledoc "Additional data used to supplement the audit log"

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    ets = :ets.new(__MODULE__, [:protected, :named_table])
    {:ok, ets}
  end

  def track(pid, data) do
    GenServer.call(__MODULE__, {:store, pid, data})
  end

  def handle_call({:store, pid, data}, _, ets) do
    :ets.insert(ets, {pid, data})
    Process.monitor(pid)
    {:reply, :ok, ets}
  end

  def get(pid \\ self()) do
    :ets.lookup(__MODULE__, pid)
    |> Enum.flat_map(&elem(&1, 1))
  end

  def handle_info({:DOWN, _, :process, pid, _}, ets) do
    :ets.delete(ets, pid)
    {:noreply, ets}
  end

  def merge_opts(opts \\ []) do
    case Process.whereis(__MODULE__) do
      nil -> opts
      _ -> opts ++ [ex_audit_additional: get()]
    end
  end
end
