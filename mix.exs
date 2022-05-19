defmodule SigilF.MixProject do
  use Mix.Project

  def project do
    [
      app: :fmt,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end
end
