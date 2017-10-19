defmodule ExAuditTest do
  use ExUnit.Case
  doctest ExAudit

  import Ecto.Query

  alias ExAudit.Test.{Repo, User, Version}

  test "should document lifecycle of an entity" do
    params = %{
      name: "Moritz Schmale",
      email: "foo@bar.com"
    }

    changeset = User.changeset(%User{}, params)

    {:ok, user} = Repo.insert(changeset)

    assert params.name == user.name
    assert params.email == user.email

    version = Repo.one(from v in Version, 
      where: v.entity_id == ^user.id,
      where: v.action == ^:created)

    assert version.action == :created
    assert version.patch.name == {:added, params.name}
    assert version.patch.email == {:added, params.email}

    params = %{
      email: "real@email.com"
    }
    changeset = User.changeset(user, params)

    {:ok, user} = Repo.update(changeset)
    version = Repo.one(from v in Version, 
      where: v.entity_id == ^user.id,
      where: v.action == ^:updated)

    assert version.patch.email == {:changed, {:primitive_change, changeset.data.email, params.email}}

    {:ok, user} = Repo.delete(user) 
    version = Repo.one(from v in Version,
      where: v.entity_id == ^user.id,
      where: v.action == ^:deleted)

    assert not is_nil(version)
  end
end
