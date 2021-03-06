defmodule JPMarc.MarcSigil do
  @moduledoc """
  Implement the "~M" sigil, which takes a string containig
  representation of JPMARC elements and return its corresponding JPMarc struct.
  """

  alias JPMarc.Record
  alias JPMarc.Leader
  alias JPMarc.ControlField, as: CF
  alias JPMarc.DataField, as: DF
  alias JPMarc.SubField, as: SF


  @doc """

  Creates JPMarc.Record

      iex> record = ~m\"\"\"
      ...> 00276nam a2200109zi 4500
      ...> 001 123456789012
      ...> 003 JTNDL
      ...> 005 20170209103923.0
      ...> 007 ta
      ...> 008 170209s2017    ja ||||g |||| |||||||jpn
      ...> 020    $c 2000 $z 978-4-123456-01-0
      ...> 245 00 $a Book title : $b subtitle / $c Yamada Taro.
      ...> \"\"\"
      00276nam a2200109zi 4500
      001 123456789012
      003 JTNDL
      005 20170209103923.0
      007 ta
      008 170209s2017    ja ||||g |||| |||||||jpn
      020    $c 2000 $z 978-4-123456-01-0
      245 00 $a Book title : $b subtitle / $c Yamada Taro.

      iex> IO.puts JPMarc.Record.subfield_value(record, "245", "a")
      Book title :

  Creates JPMarc.Leader

      iex> leader = ~m"00276nam a2200109zi 4500"
      00276nam a2200109zi 4500

      iex> JPMarc.is_leader(leader)
      true

  Creates JPMarc.ControlField

      iex> cf = ~m"001 123456789012"
      001 123456789012

      iex> JPMarc.is_controlfield(cf)
      true

  Creates JPMarc.DataField

      iex> df = ~m"245 00 $a Book title : $b subtitle / $c Yamada Taro."
      245 00 $a Book title : $b subtitle / $c Yamada Taro.

      iex> JPMarc.is_datafield(df)
      true

  Creates a list of JPMarc.ControlField and JPMarc.DataField

      iex> fields = ~m\"\"\"
      ...> 001 123456789012
      ...> 245 00 $a Book title : $b subtitle / $c Yamada Taro.
      ...> \"\"\"
      [001 123456789012, 245 00 $a Book title : $b subtitle / $c Yamada Taro.]

      iex> length(fields)
      2

      iex> JPMarc.is_controlfield(Enum.at(fields, 0))
      true

      iex> JPMarc.is_datafield(Enum.at(fields, 1))
      true
  
  """
  def sigil_m(text, []), do: _m(text, :jpmarc)
  def sigil_m(text, 'n'), do: _m(text, :ndl)
  #def sigil_m(text, 'v'), do: _m(text, :vufind)

  defp _m(text, :jpmarc) do
    elements = text |> String.split("\n") |> Enum.map(&String.trim_leading/1) |> Enum.map(&parse/1) |> List.flatten()
    case elements do
      [element|[]] -> element
      [head|tail] ->
        if JPMarc.is_leader(head),
          do: %Record{leader: head, fields: tail},
        else: [head|tail]
      _ -> elements
    end
  end

  defp _m(text, :ndl) do
    separator = "|"
    [leader|fields] = text |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.map(fn(line) ->
      case line do
        <<"LDR\t \t", leader::binary>> ->
          Leader.decode(leader)
        <<"FMT", _::binary>> -> []
        <<"SYS", _::binary>> -> []
        <<tag::bytes-size(3), "\t \t", value::binary>> ->
          if String.starts_with?(value, " |") do
            make_data_field(tag, " ", " ", value, separator)
          else
            %CF{tag: tag, value: value}
          end
        <<tag::bytes-size(3), ind1::bytes-size(1), "\t \t", value::binary>> ->
          make_data_field(tag, ind1, " ", value, separator)
        <<tag::bytes-size(3), ind1::bytes-size(1), ind2::bytes-size(1), "\t \t", value::binary>> ->
          make_data_field(tag, ind1, ind2, value, separator)
        _ -> []
      end
    end) |> List.flatten()
    %Record{leader: leader, fields: fields}
  end

  defp parse(line) do
    case line do
      <<tag::bytes-size(3), " ", ind1::bytes-size(1), ind2::bytes-size(1), " $", value::binary>> ->
        make_data_field(tag, ind1, ind2, "$" <> value, "$")
      <<tag::bytes-size(3), " ", value::binary>> ->
        %CF{tag: tag, value: value}
      <<leader::bytes-size(24)>> ->
        Leader.decode(leader)
      _ -> []
    end
  end

  defp make_data_field(tag, ind1, ind2, value, separator) do
    subfields = " " <> value
      |> String.split(" #{separator}", trim: true)
      |> Enum.map(&String.split(&1, " ", parts: 2))
      |> Enum.map(fn l -> %SF{code: List.first(l), value: List.last(l)} end)
    %DF{tag: tag, ind1: ind1, ind2: ind2, subfields: subfields}
  end
end
