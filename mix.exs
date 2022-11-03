defmodule CacheUtil.MixProject do
  use Mix.Project

  def project do
    [
      app: :cacheutil,
      escript: [main_module: CacheUtil.CLI],
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:objectutil, git: "git@github.com:ProdigyReloaded/objectutil.git"},
      {:ex_minimatch, git: "https://github.com/hez/ex_minimatch.git", tag: "v0.0.3"},

      {:exprintf, "~> 0.2.0"},
    ]
  end
end
