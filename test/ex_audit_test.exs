defmodule ExAuditTest do
  use ExUnit.Case
  doctest ExAudit

  import Ecto.Query

  alias ExAudit.Test.{Repo, User, Version, BlogPost}

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
      where: v.entity_schema == ^User,
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
      where: v.entity_schema == ^User,
      where: v.action == ^:updated)

    assert version.patch.email == {:changed, {:primitive_change, changeset.data.email, params.email}}

    {:ok, user} = Repo.delete(user) 
    version = Repo.one(from v in Version,
      where: v.entity_id == ^user.id,
      where: v.entity_schema == ^User,
      where: v.action == ^:deleted)

    assert not is_nil(version)

    versions = Repo.history(user)

    assert length(versions) == 3
  end

  test "should track custom data" do
    user = Repo.insert!(User.changeset(%User{}, %{name: "Admin", email: "admin@example.com"}))

    changeset = BlogPost.changeset(%BlogPost{}, %{
      author_id: user.id,
      title: "My First Post"
    }) 

    {:ok, blog_post} = Repo.insert(changeset, ex_audit_custom: [actor_id: user.id])

    version = Repo.one(from v in Version,
        where: v.entity_id == ^blog_post.id,
        where: v.entity_schema == ^BlogPost,
        where: v.action == ^:created)

    assert version.actor_id == user.id
  end

  test "should track custom data from plugs or similar" do
    user = Repo.insert!(User.changeset(%User{}, %{name: "Admin", email: "admin@example.com"}))

    changeset = BlogPost.changeset(%BlogPost{}, %{
      author_id: user.id,
      title: "My Second Post"
    }) 

    ExAudit.track(actor_id: user.id)

    {:ok, blog_post} = Repo.insert(changeset)

    version = Repo.one(from v in Version,
        where: v.entity_id == ^blog_post.id,
        where: v.entity_schema == ^BlogPost,
        where: v.action == ^:created)

    assert version.actor_id == user.id
  end
end
