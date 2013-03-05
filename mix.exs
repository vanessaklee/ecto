defmodule Ecto.Mixfile do
  use Mix.Project

  def project do
    [ app: :ecto,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ registered: [:ecto],
      applications: [:kernel, :stdlib, :elixir, :crypto, :ssl],
      mod: { Ecto, [] } ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ { :genx, git: "https://github.com/yrashk/genx.git" },
      { :poolboy, git: "https://github.com/devinus/poolboy.git" },
      { :epgsql, git: "https://github.com/wg/epgsql.git" },
      { :epgsql_pool, git: "https://github.com/devinus/epgsql_pool.git" } ]
  end
end
