defmodule ExAudit.Patch do
  @doc """
  Applies the patch to the given term
  """
  def patch(_, {:primitive_change, _, b}) do
    b
  end

  def patch(a, :not_changed) do
    a
  end

  def patch(list, changes) when is_list(list) and is_list(changes) do
    changes
    |> Enum.reverse()
    |> Enum.reduce(list, fn
      {:added_to_list, i, el}, list ->
        List.insert_at(list, i, el)

      {:removed_from_list, i, _}, list ->
        List.delete_at(list, i)

      {:changed_in_list, i, change}, list ->
        List.update_at(list, i, &patch(&1, change))
    end)
  end

  def patch(map, changes) when is_map(map) and is_map(changes) do
    changes
    |> Enum.reduce(map, fn
      {key, {:added, b}}, map ->
        Map.put(map, key, b)

      {key, {:removed, _}}, map ->
        Map.delete(map, key)

      {key, {:changed, changes}}, map ->
        Map.update!(map, key, &patch(&1, changes))
    end)
  end
end
