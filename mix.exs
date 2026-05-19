defmodule BowlingGame.MixProject do
  use Mix.Project

  def project do
    [
      app: :bowling_game,
      version: "0.1.0",
      description: "The now classic bowling game kata by Bob Martin, implemented in Elixir.",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
