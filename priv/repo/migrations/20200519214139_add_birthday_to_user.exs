defmodule ExAudit.Test.Repo.Migrations.AddBirthdayToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :birthday, :date
    end
  end
end
