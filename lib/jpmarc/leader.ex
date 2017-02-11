defmodule JPMarc.Leader do
  @moduledoc"""
  Tools for working with JPMARC Leader
  """

  @typedoc """
      Type that represents `JPMarc.Leader` struct

      This constructed with `:length` as integer, `:status` as String, `:type` of String, `:level` as String, `:base` as integer, `:encoding` String, `:format` String
  """
  @type t :: %JPMarc.Leader{length: integer, status: String.t, type: String.t, level: String.t, base: integer, encoding: String.t, format: String.t}
  defstruct length: 0, status: "n", type: "a", level: "m", base: 0, encoding: "z", format: "i"

  @doc"""
  Decode the string representation to JPMarc.Leader struct
  """
  @spec decode(String.t)::JPMarc.Leader.t
  def decode(leader) do
    <<length::bytes-size(5), status::bytes-size(1), type::bytes-size(1),
      level::bytes-size(1), _::bytes-size(4), base::bytes-size(5), encoding::bytes-size(1), format::bytes-size(1), _::binary>> = leader
    base = if base == "     ", do: "00000", else: base
    %__MODULE__{length: String.to_integer(length), status: status, type: type, level: level, base: String.to_integer(base), encoding: encoding, format: format}
  end

  @doc """
    Return the MARC Format of the leader
  """
  @spec to_marc(JPMarc.Leader.t)::String.t
  def to_marc(l) do
    length = l.length |> Integer.to_string |> String.pad_leading(5, "0")
    base = l.base |> Integer.to_string |> String.pad_leading(5, "0")
    "#{length}#{l.status}#{l.type}#{l.level} a22#{base}#{l.encoding}#{l.format} 4500"
  end

  @doc"""
  Return a tuple representing its xml element
  """
  @spec to_xml(JPMarc.Leader.t)::tuple
  def to_xml(leader) do
    {:leader, nil, JPMarc.Leader.to_marc(leader)}
  end

  defimpl Inspect, for: JPMarc.Leader do
    def inspect(leader, _opts) do
      JPMarc.Leader.to_marc(leader)
    end
  end

  defimpl String.Chars, for: JPMarc.Leader do
    def to_string(leader) do
      JPMarc.Leader.to_marc(leader)
    end
  end
end
