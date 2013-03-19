Code.require_file "../../test_helper.exs", __FILE__

defmodule URI.ParserTest do
  use ExUnit.Case
  alias Ecto.URI, as: Parser
  alias Ecto.URI.ParseError, as: ParseError

  test :default_port, do: assert 5432 == Parser.default_port

  test :parse_simple_uri do
    url      = "ecto+postgres://localhost/thedatabase"
    actual   = Parser.parse(url)
    expected = [ host: "localhost",
                 port: 5432,
                 db:   "thedatabase",
                 user: nil,
                 pass: nil ]
    assert Keyword.equal?(expected, actual)
  end

  test :parse_url_with_user do
    url      = "ecto+postgres://user@localhost/thedatabase"
    actual   = Parser.parse(url)
    expected = [ host: "localhost",
                 port: 5432, 
                 db:   "thedatabase",
                 user: "user",
                 pass: nil ]
    assert Keyword.equal?(expected, actual)
  end

  test :parse_full_url do
    url      = "ecto+postgres://user:pass@localhost/thedatabase"
    actual   = Parser.parse(url)
    expected = [ host: "localhost",
                 port: 5432, 
                 db:   "thedatabase",
                 user: "user",
                 pass: "pass" ]
    assert Keyword.equal?(expected, actual)
  end

  test :parse_options do
    url      = "ecto+postgres://user:pass@localhost/thedatabase?size=10&overflow=5&shoe=14&name=foo"
    actual   = Parser.parse(url)
    expected = [ host: "localhost",
                 port: 5432, 
                 db:   "thedatabase",
                 user: "user",
                 pass: "pass",
                 opts: [ size: 10, max_overflow: 5, name: :foo ]]
    assert Keyword.equal?(expected, actual)
  end

  test :bad_uri, do: assert_raise ParseError, fn ->
    Parser.parse ":mecto"
  end

  test :no_password, do: assert_raise ParseError, fn ->
    Parser.parse "ecto+postgres://user:@localhost/db"
  end

  test :no_user, do: assert_raise ParseError, fn ->
    Parser.parse "ecto+postgres://:pass@host/db"
  end

  test :no_db, do: assert_raise ParseError, fn ->
    Parser.parse "ecto+postgres://user:pass@host"
  end
  
  test :no_db_with_args, do: assert_raise ParseError, fn ->
    Parser.parse "ecto+postgres://user:pass@host?args"
  end

  test :no_host, do: assert_raise ParseError, fn ->
    Parser.parse "ecto+postgres://user:pass@/db"
  end
end
