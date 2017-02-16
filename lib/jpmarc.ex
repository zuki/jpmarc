defmodule JPMarc do
  @moduledoc """
    Tools for working wiht JPMARC records
  """
  import XmlBuilder
  alias JPMarc.Record
  alias JPMarc.Leader
  alias JPMarc.ControlField
  alias JPMarc.DataField

  @rs "\x1d"   # Record separator

  @doc """
  Is element a leader?
  """
  @spec is_leader(any)::boolean
  def is_leader(element), do: element.__struct__ == Leader

  @doc """
  Is element a control field?
  """
  @spec is_controlfield(any)::boolean
  def is_controlfield(element), do: element.__struct__ == ControlField

  @doc """
  Is element a data field?
  """
  @spec is_datafield(any)::boolean
  def is_datafield(element), do: element.__struct__ == DataField

  @doc """
    Parse a marc file and return List of `JPMarc.Record` struct
  """
  @spec parse_file(String.t)::[JPMarc.Record.t]
  def parse_file(file) do
    case File.read(file) do
      {:ok, marc} ->
        String.split(marc, @rs, trim: true) |> Enum.map(&Record.from_marc/1)
      {:error, reason} ->
        IO.puts "Error occured: #{reason}"
        []
    end
  end

  @doc """
    Parse a marc file which contains one marc record, and return a `JPMarc.Record` struct
  """
  @spec parse_marc(String.t)::JPMarc.Record.t
  def parse_marc(file), do: JPMarc.parse_file(file) |> Enum.at(0)

  @doc """
    Return the String representing MARC Format of the JPMarc.Record struct (one or List of that)
  """
  @spec to_marc(JPMarc.Record.t|[JPMarc.Record.t])::String.t
  def to_marc(records) when is_list(records) do
    records |> Enum.map(&Record.to_marc/1) |> Enum.join("")
  end
  def to_marc(record), do: to_marc([record])

  @doc """
  Return the MARCXML Format of JPMarc.Record struct (One or List of that)
  """
  @spec to_xml(JPMarc.Record.t|[JPMarc.Record.t])::String.t
  def to_xml(records) when is_list(records) do
    xmls = records |> Enum.map(&Record.to_xml/1)
    doc(:collection, %{xmlns: "http://www.loc.gov/MARC21/slim"}, xmls)
  end
  def to_xml(record), do: to_xml([record])

  @doc """
  Return the JSON Format of JPMarc.Record struct (One or List of that)
  """
  @spec to_json(JPMarc.Record.t|[JPMarc.Record.t])::String.t
  def to_json(records) when is_list(records) do
    "[#{records |> Enum.map(&Record.to_json/1) |> Enum.join(",")}]"
  end
  def to_json(record), do: to_json([record])

end
