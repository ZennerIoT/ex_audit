defmodule PrecisionTest do
  use ExUnit.Case,
    async: false

  import Ecto.Query

  alias ExAudit.Test.{Repo, User, Version, Util}

  setup_all do
    current = Application.get_env(:ex_audit, :precision)

    Application.put_env(:ex_audit, :precision, :microsecond)

    on_exit(fn -> Application.put_env(:ex_audit, :precision, current) end)
  end

  test "adjust the precision to `second` in the field `recorded_at`" do
    user = Util.create_user("Juan Zuñiga")

    changeset = User.changeset(user, %{name: "@neodevelop"})

    assert {:ok, user} = Repo.update(changeset)

    query =
      from(v in Version,
        where: v.entity_id == ^user.id,
        where: v.entity_schema == ^User
      )

    assert 2 = Repo.aggregate(query, :count, :id)
  end
end
