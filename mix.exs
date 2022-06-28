defmodule SigilF.MixProject do
  use Mix.Project

  def project do
    [
      app: :fmt,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      test_coverage: [
        ignore_modules: [Fmt.Parser.Helpers]
      ],
      deps: [
        {:nimble_parsec, "~> 1.2", runtime: false},
        {:stream_data, "~> 0.5.0", only: [:dev, :test]},
        {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
      ]
    ]
  end
end
