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
      mod: { Ecto.Application, [] } ]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [ { :genx, github: "yrashk/genx" },
      { :poolboy, github: "devinus/poolboy" },
      { :epgsql, github: "wg/epgsql" },
      { :epgsql_pool, github: "devinus/epgsql_pool" } ]
  end
end
