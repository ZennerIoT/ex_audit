defmodule ExAudit.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_audit,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      elixirc_paths: paths(Mix.env),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  def paths(:test) do
    paths(:default) ++ ["./example"]
  end

  def paths(:default) do
    ["./lib"]
  end

  def paths(_), do: paths(:default)


  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ExAudit, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.2", only: :test},
      {:postgrex, "~> 0.13.3", only: :test},
      {:excoveralls, "~> 0.7", only: :test}
    ]
  end
end
