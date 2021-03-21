defmodule AwsExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :aws_example,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AwsExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jackalope, "~> 0.2.0"},
      {:x509, "~> 0.8.2"},
      {:tortoise, path: "../tortoise", override: true}
    ]
  end
end
