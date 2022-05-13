defmodule ExAudit.TelemetryTest do
  use ExUnit.Case, async: true

  alias ExAudit.Test.Repo
  alias ExAudit.Test.User
  alias ExAudit.Test.Version

  test "should received telemetry event" do
    :telemetry.attach(
      "init",
      [:ex_audit, :insert_version],
      fn event_name, event_measurement, event_metadata, _handle_config ->
        send(self(), {:event_name, event_name})
        send(self(), {:event_measurement, event_measurement})
        send(self(), {:event_metadata, event_metadata})
      end,
      []
    )

    %{id: user_id} =
      Repo.insert!(User.changeset(%User{}, %{name: "Admin", email: "admin@example.com"}))

    assert_received {:event_name, [:ex_audit, :insert_version]}, 1_000
    assert_receive {:event_measurement, %{system_time: _time}}, 1_000

    assert_receive {:event_metadata, event_metadata}, 1_000

    assert %Version{
             action: :created,
             actor_id: nil,
             entity_id: ^user_id,
             entity_schema: User
           } = event_metadata
  end
end
