defmodule JPMarc do
  @moduledoc """
    Tools for working wiht JPMARC records
  """
  import XmlBuilder
  alias JPMarc.Record

  @rs "\x1d"   # Record separator

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
end
