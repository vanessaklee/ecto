defmodule Ecto.Validations do
  defrecord Date, allow_nil: false
  defrecord DateTime, allow_nil: false

  defimpl Validatex.Validate, for: Date do
    def valid?(Date[allow_nil: true], nil), do: true
    def valid?(Date[], { year, month, day })
      when is_integer(year) and is_integer(month) and is_integer(day), do: true

    def valid?(Date[], _value), do: :bad_date
  end

  defimpl Validatex.Validate, for: DateTime do
    def valid?(DateTime[allow_nil: true], nil), do: true
    def valid?(DateTime[], { { year, month, day }, { hour, minute, second } })
      when is_integer(year) and is_integer(month) and is_integer(day)
       and is_integer(hour) and is_integer(minute) and is_integer(second), do: true

    def valid?(DateTime[], _value), do: :bad_datetime
  end

  defrecord Email, check_domain: false, allow_nil: false

  defimpl Validatex.Validate, for: Email do
    def valid?(Email[allow_nil: true], nil), do: true

    def valid?(Email[check_domain: check_domain], value) when is_binary(value) do
      # Willful violation of RFC 5322
      if value =~ %r"^[^@]+@[^@]+\.[^@]+$" do
        if check_domain do
          [ _, domain ] = String.split(value, "@")
          case :inet.gethostbyname(binary_to_list(domain)) do
            { :error, :nxdomain } -> :bad_domain
            _ -> true
          end
        else
          true
        end
      else
        :bad_format
      end
    end

    def valid?(Email[], _value), do: :bad_email
  end

  defrecord Phone, min_length: 7, allow_nil: false

  defimpl Validatex.Validate, for: Phone do
    def valid?(Phone[allow_nil: true], nil), do: true

    def valid?(Phone[min_length: min], value) when is_binary(value) do
      digits = Regex.scan %r/\d/, value
      length(digits) >= min || :bad_length
    end

    def valid?(Phone[], _value), do: :bad_phone
  end

  defrecord OneOf, allowed: []

  defimpl Validatex.Validate, for: OneOf do
    def valid?(OneOf[allowed: allowed], value) do
      Enum.member?(allowed, value) || :not_allowed
    end
  end
end
