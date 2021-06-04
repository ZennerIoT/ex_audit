defmodule ExAudit.TelemetryTest do
  use ExUnit.Case, async: true

  alias ExAudit.Test.Repo
  alias ExAudit.Test.User

  test "should received telemetry event" do
    :telemetry.attach(
      "init",
      [:ex_audit, :insert_version],
      fn event_name, event_measurement, event_metadata, _handle_config ->
        send(self(), event_name)
        send(self(), event_measurement)
        send(self(), event_metadata)
      end,
      []
    )

    user = Repo.insert!(User.changeset(%User{}, %{name: "Admin", email: "admin@example.com"}))

    assert_receive [:ex_audit, :insert_version], 1_000
    assert_receive %{system_time: _time}, 1_000

    assert_receive %{action: :created, entity_id: entity_id, entity_schema: User, patch: patch},
                   1_000

    assert is_map(patch)
  end
end
