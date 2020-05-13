defmodule ExAudit do
  @doc """
  Tracks the given keyword list of data for the current process
  """
  def track(data) do
    Process.put(:ex_audit_custom, data)
  end
end
