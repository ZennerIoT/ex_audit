defmodule PatchTest do
  use ExUnit.Case

  alias ExAudit.{Diff, Patch}
  doctest Patch

  test "should apply primitive changes" do
    assert_patching(:foo, :bar)
  end

  test "should cope with :not_changed" do
    assert_patching(:foo, :foo)
  end

  test "should apply patches to lists" do
    assert_patching([1, 2, 3], [1, 2, 4, 5])
    assert_patching([1, 2, 3], [])
  end

  test "should apply patches to maps" do
    assert_patching(%{a: 1, b: 2}, %{a: 3, b: 4})
    assert_patching(%{}, %{foo: 3})
    assert_patching(%{foo: 42}, %{})
  end

  test "should apply patches to complex structures" do
    a = [%{foo: [1, 2, 3]}]
    b = [%{foo: [1, 2, 3, 4]}]

    assert_patching(a, b)
  end

  defp assert_patching(a, b) do
    patch = Diff.diff(a, b)
    assert b == Patch.patch(a, patch)
    assert a == Patch.patch(b, Diff.reverse(patch))
  end
end
