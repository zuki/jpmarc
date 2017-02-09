defmodule JPMarc do
  @moduledoc """
    Library for parsing JPMARC
  """
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
    leader = parse_leader(leader)
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
    marc = JPMarc.Leader.to_marc(record.leader) <> directories <> @fs <> data <> @rs
    l = %Leader{record.leader | length: byte_size(marc), base: (25 + byte_size(directories))}
    Leader.to_marc(l) <> directories <> @fs <> data <> @rs
  end

  defp get_directories(block), do: _get_directories(block, [])
  defp _get_directories("", acc) do
    Enum.reverse acc
  end
  defp _get_directories(<<tag::bytes-size(3), length::bytes-size(4), position::bytes-size(5), rest::binary>>, acc) do
    acc = [{tag, String.to_integer(length), String.to_integer(position)} | acc]
    _get_directories(rest, acc)
  end

  defp parse_leader(leader) do
    <<length::bytes-size(5), status::bytes-size(1), type::bytes-size(1),
      level::bytes-size(1), _::bytes-size(4), base::bytes-size(5), encoding::bytes-size(1), format::bytes-size(1), _::binary>> = leader
    %Leader{length: String.to_integer(length), status: status, type: type, level: level, base: String.to_integer(base), encoding: encoding, format: format}
  end

  defp parse_tag_data(tag, <<ind1::bytes-size(1), ind2::bytes-size(1), @ss, rest::binary>>) do
    subfields = parse_subfields(rest)
    %DataField{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}
  end

  defp parse_tag_data(tag, data) do
    %ControlField{tag: tag, value: String.trim_trailing(data, @fs)}
  end

  defp parse_subfields(data) do
    data = String.trim_trailing(data, @fs)
    String.split(data, @ss, trim: true)
      |> Enum.map(fn chunk ->
        <<code::bytes-size(1), value::binary>> = chunk
        %SubField{code: code, value: value}
    end)
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
end
