Code.require_file "../../test_helper.exs", __FILE__

defmodule Ecto.ValidationsTest do
  use ExUnit.Case

  alias Validatex.Validate, as: V
  alias Ecto.Validations.Email, as: Email
  alias Ecto.Validations.Phone, as: Phone
  alias Ecto.Validations.Date, as: Date
  alias Ecto.Validations.DateTime, as: DateTime
  alias Ecto.Validations.OneOf, as: OneOf

  test Email do
    assert V.valid? Email[], "gary@google.com"
    assert V.valid? Email[], "gary+snail@google.co.uk"
    assert V.valid?(Email[], "gary2garythesnail.com") == :bad_format
    assert V.valid? Email[check_domain: true], "gary@google.com"
    assert V.valid?(Email[check_domain: true], "gary@gewgla.com") == :bad_domain
  end

  test Phone do
    assert V.valid? Phone[], "+1 (512) 635-4565"
    assert V.valid? Phone[], "1-888-737-9266 x4565"
    assert V.valid?(Phone[], "gary") == :bad_length
  end

  test Date do
    assert V.valid? Date[], { 2013, 3, 15 }
    assert V.valid?(Date[], { 2013, 3, 15.0 }) == :bad_date
    assert V.valid?(Date[], { 2013, '3', 15 }) == :bad_date
    assert V.valid?(Date[], { "2013", 3, 15 }) == :bad_date
    assert V.valid?(Date[], "gary") == :bad_date
  end

  test DateTime do
    assert V.valid? DateTime[], { { 2013, 3, 15 }, { 3, 42, 0 } }
    assert V.valid?(DateTime[], { { 2013, 3, 15.0 }, { 3, 42, 0 } }) == :bad_datetime
    assert V.valid?(DateTime[], { { 2013, '3', 15 }, { 3, 42, 0 } }) == :bad_datetime
    assert V.valid?(DateTime[], { { "2013", 3, 15 }, { 3, 42, 0 } }) == :bad_datetime
    assert V.valid?(DateTime[], { { 2013, 3, 15 }, { 3, 42, 0.0 } }) == :bad_datetime
    assert V.valid?(DateTime[], { { 2013, 3, 15 }, { 3, '42', 0 } }) == :bad_datetime
    assert V.valid?(DateTime[], { { 2013, 3, 15 }, { "3", 42, 0 } }) == :bad_datetime
    assert V.valid?(DateTime[], "gary") == :bad_datetime
  end

  test OneOf do
    assert V.valid? OneOf[allowed: ["M", "F"]], "M"
    assert V.valid?(OneOf[allowed: ["X", "Y"]], "Z") == :not_allowed
  end
end
