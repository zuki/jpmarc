defmodule JPMarc.Leader do
  @typedoc """
      Type that represents `JPMarc.Leader` struct

      This constructed with `:length` as integer, `:status` as String, `:type` of String, `:level` as String, `:base` as integer, `:encoding` String, `:format` String
  """
  @type t :: %JPMarc.Leader{length: integer, status: String.t, type: String.t, level: String.t, base: integer, encoding: String.t, format: String.t}
  defstruct length: 0, status: "n", type: "a", level: "m", base: 0, encoding: "z", format: "i"

  @doc """
    Return the MARC Format of the leader
  """
  @spec to_marc(JPMarc.Leader.t)::String.t
  def to_marc(l) do
    length = l.length |> Integer.to_string |> String.pad_leading(5, "0")
    base = l.base |> Integer.to_string |> String.pad_leading(5, "0")
    "#{length}#{l.status}#{l.type}#{l.level} a22#{base}#{l.encoding}#{l.format} 4500"
  end

end
