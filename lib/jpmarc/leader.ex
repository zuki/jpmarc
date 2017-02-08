defmodule JPMarc.Leader do
  @typedoc """
      Type that represents `JPMarc.Leader` struct

      This constructed with `:length` as integer, `:status` as binary, `:type` of binary, `:level` as binary, `:base` as integer, `:encoding` binary, `:format` binary
  """
  @type t :: %JPMarc.Leader{length: integer, status: binary, type: binary, level: binary, base: integer, encoding: binary, format: binary}
  defstruct length: 0, status: "", type: "", level: "", base: 0, encoding: "z", format: "i"

  @doc """
    Return the MARC Format of the leader
  """
  def to_marc(l) do
    length = l.length |> Integer.to_string |> String.pad_leading(5, "0")
    base = l.base |> Integer.to_string |> String.pad_leading(5, "0")
    "#{length}#{l.status}#{l.type}#{l.level} a22#{base}#{l.encoding}#{l.format} 4500"
  end

end
