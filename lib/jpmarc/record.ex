defmodule JPMarc.Record do
  @moduledoc """
    Tools for working with JPMARC Record
  """
  import XmlBuilder
  alias JPMarc.Leader
  alias JPMarc.ControlField
  alias JPMarc.DataField
  alias JPMarc.SubField

  @rs "\x1d"   # Record separator
  @fs "\x1e"   # Field separator
  @ss "\x1f"   # Subfield separator
  @leader_length 24

  @typedoc """
      Type that represents `JPMarc.Record` struct

      This is constructed with `:leader` as `JPMarc.Leader.t`, `:control_fiels` as List of `JPMarc.ControlField.t` adn `:data_fields` as List of `JPMarc.DataField.t`
  """
  @type t :: %__MODULE__{leader: Leader.t, control_fields: [ControlField.t], data_fields: [DataField.t]}
  defstruct leader: nil, control_fields: [], data_fields: []

  @doc """
    Decode the String of a marc and return `JPMarc.Record` struct
  """
  @spec from_marc(String.t)::t
  def from_marc(marc) do
    <<leader::bytes-size(@leader_length), rest::binary>> = marc
    leader = Leader.decode(leader)
    length_of_dirs = leader.base - @leader_length - 1 # -1 for @fs
    <<dir_block::bytes-size(length_of_dirs), @fs, data:: binary>> = rest

    directories = get_directories(dir_block)
    fields = for {tag, length, position} <- directories do
      tag_data = binary_part(data, position, length)
      parse_tag_data(tag, tag_data)
    end
    {control_fields, data_fields} = Enum.split_with(fields, &(&1.__struct__ == ControlField))
    %__MODULE__{leader: leader, control_fields: control_fields, data_fields: data_fields}
  end

  @doc """
    Return the MARC Format of the JPMarc struct
  """
  @spec to_marc(t)::String.t
  def to_marc(record) do
    {directories, data} = make_directories_data(record.control_fields ++ record.data_fields)
    marc = Leader.to_marc(record.leader) <> directories <> @fs <> data <> @rs
    l = %Leader{record.leader | length: byte_size(marc), base: (@leader_length + 1 + byte_size(directories))}
    Leader.to_marc(l) <> directories <> @fs <> data <> @rs
  end

  @doc """
  Return the MARCXML Format of the JPMarc struct
  """
  @spec to_xml(t)::String.t
  def to_xml(record) do
    sorted = sort(record)
    {control_fields, data_fields} = Enum.split_with(sorted.fields, &(&1.__struct__ == ControlField))
    cf_xml = control_fields |> Enum.map(&ControlField.to_xml/1)
    df_xml = data_fields |> Enum.map(&DataField.to_xml/1)
    xml = [Leader.to_xml(sorted.leader)] ++ cf_xml ++ df_xml
    element(:record, nil, xml)
  end

  @doc """
    Sort its fields by tag and subfields of field
  """
  @spec sort(t)::t
  def sort(record) do
    sorted_control_fields = record.control_fields |> Enum.sort(&(&1.tag <= &2.tag))
    sorted_data_fields = record.data_fields |> Enum.map(&DataField.sort/1) |> Enum.sort(&(&1.tag<>&1.ind1<>&1.ind2 <= &2.tag<>&2.ind1<>&2.ind2))
    %__MODULE__{record | control_fields: sorted_control_fields, data_fields: sorted_data_fields}
  end

  defp get_directories(block), do: _get_directories(block, [])
  defp _get_directories("", acc) do
    Enum.reverse acc
  end
  defp _get_directories(<<tag::bytes-size(3), length::bytes-size(4), position::bytes-size(5), rest::binary>>, acc) do
    acc = [{tag, String.to_integer(length), String.to_integer(position)} | acc]
    _get_directories(rest, acc)
  end

  defp parse_tag_data(tag, <<ind1::bytes-size(1), ind2::bytes-size(1), @ss, rest::binary>>) do
    subfields = SubField.decode(rest)
    %DataField{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}
  end
  defp parse_tag_data(tag, data) do
    %ControlField{tag: tag, value: String.trim_trailing(data, @fs)}
  end

  defp make_directories_data(fields), do: _make_directories_data(fields, {[], []}, 0)
  defp _make_directories_data([], {dir, data}, _pos),
    do: {
      dir |> Enum.reverse |> Enum.join,
      data |> Enum.reverse |> Enum.join
    }
  defp _make_directories_data([head|tail], {dir, data}, pos) do
    marc = case head.__struct__ do
      ControlField -> ControlField.to_marc(head)
      DataField -> DataField.to_marc(head)
    end

    length = byte_size(marc)
    length_str = length |> Integer.to_string |> String.pad_leading(4, "0")
    pos_str = pos |> Integer.to_string |> String.pad_leading(5, "0")

    _make_directories_data(tail, {[head.tag <> length_str <> pos_str|dir] , [marc|data]}, pos + length)
  end

  defimpl Inspect do
    def inspect(%JPMarc.Record{leader: leader, control_fields: control_fields, data_fields: data_fields}, _opts) do
      "#{leader}\n#{Enum.join(control_fields ++ data_fields, "\n")}"
    end
  end

  defimpl String.Chars, for: JPMarc.Record do
    def to_string(%JPMarc.Record{leader: leader, control_fields: control_fields, data_fields: data_fields}) do
      "#{leader}, #{Enum.join(control_fields ++ data_fields, "\n")}"
    end
  end

end
