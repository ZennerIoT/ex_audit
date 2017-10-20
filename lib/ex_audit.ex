defmodule ExAudit do
  use Application
  
  def start(_, _) do
    import Supervisor.Spec

    children = [
      worker(ExAudit.CustomData, [])
    ]

    opts = [strategy: :one_for_one, name: ExAudit.Supervisor]
    Supervisor.start_link(children, opts)
  end
  @moduledoc """
  # Configuration

   * `:only`: a whitelist of tables and ecto schema modules. If set, ExAudit will only watch 
     changes in these tables
   * `:except`: a blacklist of tables and ecto schema modules. If set, ExAudit watches any table but
     these

  `:only` and `:except` are mutually exclusive. If none of the 2 options is set, ExAudit watches all tables.
  """

  def track(data) do
    track_pid(self(), data)
  end

  def track_pid(pid, data) do
    ExAudit.CustomData.track(pid, data)
  end
end
