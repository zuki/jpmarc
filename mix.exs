defmodule JPMarc.Mixfile do
  use Mix.Project

  def project do
    [app: :jpmarc,
     version: "0.1.0",
     compilers: Mix.compilers ++ [:po],
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     docs: [
       main: "JPMarc",
       formatter: Exgettext.HTML,
       source_url: "https://github.com/zuki/jpmarc"
    ],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.14"},
      {:exgettext, github: "zuki/exgettext"}
    ]
  end
end
