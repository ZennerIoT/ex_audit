defmodule ExAudit do
  use Application

  def start(_, _) do
    children = [
      ExAudit.CustomData
    ]

    opts = [strategy: :one_for_one, name: ExAudit.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Tracks the given keyword list of data for the current process
  """
  def track(data) do
    track_pid(self(), data)
  end

  @doc """
  Tracks the given keyword list of data for the given process
  """
  def track_pid(pid, data) do
    ExAudit.CustomData.track(pid, data)
  end
end
