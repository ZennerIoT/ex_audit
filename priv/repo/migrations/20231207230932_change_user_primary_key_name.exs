defmodule ExAudit.Test.Repo.Migrations.ChangeUserPrimaryKeyName do
  use Ecto.Migration

  def change do
    rename table(:users), :id, to: :user_id
  end
end
