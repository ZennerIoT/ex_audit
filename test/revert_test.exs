defmodule RevertTest do
  use ExUnit.Case

  import Ecto.Query

  alias ExAudit.Test.{Repo, User, Version, Util}

  test "should revert changes" do
    user = Util.create_user()

    ExAudit.track(actor_id: user.id)

    user2 = Util.create_user("Horst Dieter Schaf", "horst.dieter@schaf.de")

    assert length(Repo.history(user2)) == 1

    ch = User.changeset(user2, %{name: "Horst Dieter Schaf-Kuh"})

    Repo.update(ch)

    version =
      Repo.one(
        from(v in Version,
          where: v.entity_id == ^user2.id,
          where: v.entity_schema == ^User,
          where: v.action == ^:updated
        )
      )

    # revert an update

    {:ok, user2_rolled_back} = Repo.revert(version)

    assert user2_rolled_back.name == "Horst Dieter Schaf"

    version_rollback =
      Repo.one(
        from(v in Version,
          where: v.entity_id == ^user2.id,
          where: v.entity_schema == ^User,
          where: v.action == ^:updated,
          where: v.rollback == true
        )
      )

    assert version_rollback != nil

    # revert multiple things, including update and delete

    Repo.delete(user2)

    {:ok, user2_rolled_back} = Repo.revert(version)

    assert user2_rolled_back.name == "Horst Dieter Schaf"

    version_rollback =
      Repo.one(
        from(v in Version,
          where: v.entity_id == ^user2.id,
          where: v.entity_schema == ^User,
          where: v.action == ^:updated,
          where: v.rollback == true,
          limit: 1,
          order_by: [desc: v.recorded_at]
        )
      )

    assert version_rollback != nil
  end

  test "undo a create" do
    user = Util.create_user("wrong", "wrong@wrongwrong.wom")

    assert [version] = Repo.history(user)
    assert {:ok, nil} = Repo.revert(version)

    assert nil == Repo.get(User, user.id)
  end
end
