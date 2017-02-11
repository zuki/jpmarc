defmodule JPMarc do
  @moduledoc """
    Library for parsing JPMARC
  """
  import XmlBuilder
  alias JPMarc.Leader
  alias JPMarc.ControlField
  alias JPMarc.DataField
  alias JPMarc.SubField

  @rs "\x1d"   # Record separator
  @fs "\x1e"   # Field separator
  @ss "\x1f"   # Subfield separator

  @typedoc """
      Type that represents `JPMarc` struct

      This is constructed with `:leader` as `JPMarc.Leader.t`, `:fiels` as List of `JPMarc.ControlField.t` or `JPMarc.DataField.t`
  """
  @type t :: %JPMarc{leader: Leader.t, fields: [ControlField.t | DataField.t]}
  defstruct leader: nil, fields: []

  @doc """
    Parse a marc file and return `JPMarc` struct or nil if a error occures when reading the specific file
  """
  @spec parse_file(binary)::(JPMarc.t|nil)
  def parse_file(file) do
    case File.read(file) do
      {:ok, marc} ->
        parse_record(marc)
      {:error, reason} ->
        IO.puts "Error occured: #{reason}"
        nil
    end
  end

  @doc """
    Parse a binary of marc and return `JPMarc` struct
  """
  @spec parse_record(binary)::JPMarc.t
  def parse_record(marc) do
    <<leader::bytes-size(24), rest::binary>> = marc
    leader = Leader.decode(leader)
    length_of_dirs = leader.base - 24 - 1 # -1 for \x1e
    <<dir_block::bytes-size(length_of_dirs), @fs, data:: binary>> = rest

    directories = get_directories(dir_block)
    fields = for {tag, length, position} <- directories do
      tag_data = binary_part(data, position, length)
      parse_tag_data(tag, tag_data)
    end
    %__MODULE__{leader: leader, fields: fields}
  end

  @doc """
    Return the MARC Format of the JPMarc struct
  """
  @spec to_marc(JPMarc.t)::String.t
  def to_marc(record) do
    {directories, data} = make_directories_data(record.fields)
    marc = Leader.to_marc(record.leader) <> directories <> @fs <> data <> @rs
    l = %Leader{record.leader | length: byte_size(marc), base: (25 + byte_size(directories))}
    Leader.to_marc(l) <> directories <> @fs <> data <> @rs
  end

  @doc"""
  Return the MARCXML Format of the JPMarc struct
  """
  @spec to_xml(JPMarc.DataField.t)::String.t
  def to_xml(record) do
    sorted = sort(record)
    {control_fields, data_fields} = Enum.split_with(sorted.fields, &(&1.__struct__ == ControlField))
    cf_xml = control_fields |> Enum.map(&ControlField.to_xml/1)
    df_xml = data_fields |> Enum.map(&DataField.to_xml/1)
    xml = [Leader.to_xml(sorted.leader)] ++ cf_xml ++ df_xml
    XmlBuilder.doc(:collection, %{xmlns: "http://www.loc.gov/MARC21/slim"}, xml)
  end


  @doc """
    Sort its fields by tag and subfields of field
  """
  @spec sort(JPMarc.t)::JPMarc.t
  def sort(record) do
    {control_fields, data_fields} =
      Enum.split_with(record.fields, &(&1.__struct__ == ControlField))
    sorted_control_fields = control_fields |> Enum.sort(&(&1.tag <= &2.tag))
    sorted_data_fields = data_fields |> Enum.map(&DataField.sort/1) |> Enum.sort(&(&1.tag<>&1.ind1<>&1.ind2 <= &2.tag<>&2.ind1<>&2.ind2))
    %__MODULE__{record | fields: sorted_control_fields ++ sorted_data_fields}
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
    def inspect(%JPMarc{leader: leader, fields: fields}, _opts) do
      "#{leader}\n#{Enum.join(fields, "\n")}"
    end
  end

  defimpl String.Chars, for: JPMarc do
    def to_string(%JPMarc{leader: leader, fields: fields}) do
      "#{leader}, #{Enum.join(fields, ", ")}"
    end
  end

end
