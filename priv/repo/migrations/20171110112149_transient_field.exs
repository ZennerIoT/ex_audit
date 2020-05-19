defmodule ExAudit.Test.Repo.Migrations.TransientField do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:transient_field, :integer)
    end
  end
end
