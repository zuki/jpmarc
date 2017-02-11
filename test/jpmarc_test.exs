defmodule JPMarcTest do
  use ExUnit.Case, async: true
  alias JPMarc
  alias JPMarc.Record
  alias JPMarc.Leader
  alias JPMarc.ControlField, as: CF
  alias JPMarc.DataField, as: DF
  alias JPMarc.SubField, as: SF
  import JPMarc.MarcSigil

  setup_all do
    records = JPMarc.parse_file("test/data/test.mrc")
    record = Enum.at(records, 0)
    {:ok, [
      records: records,
      record: record,
      leader: record.leader,
      control_fields: record.control_fields,
      data_fields: record.data_fields]}
  end

  test "Parse MARC file", %{records: records} do
    assert length(records) == 1
  end

  test "Parse leader", %{leader: leader} do
    assert leader.type == "a"
    assert leader.length == 276
  end

  test "Parse ControlFields", %{control_fields: control_fields} do
    assert length(control_fields) == 5

    first_control_field = Enum.at(control_fields, 0)
    assert first_control_field.tag == "001"
    assert first_control_field.value == "123456789012"
  end

  test "Parse DataFields", %{data_fields: data_fields} do
    assert length(data_fields) == 2

    first_data_field = Enum.at(data_fields, 0)
    assert first_data_field.ind1 == " "
    assert first_data_field.ind2 == " "
    assert length(first_data_field.subfields) == 2

    first_subfield = Enum.at(first_data_field.subfields, 0)
    assert first_subfield.code == "c"
    assert first_subfield.value == "2000円"
  end

  test "Write a MARC file", %{record: record} do
    marc = JPMarc.to_marc([record])
    {:ok, org} = File.read("test/data/test.mrc")
    assert marc == org
  end

  test "DataField sort" do
    df = %DF{tag: "100", subfields: [%SF{code: "b", value: "ab"}, %SF{code: "a", value: "cd"}]}
    sorted = %DF{tag: "100", subfields: [%SF{code: "a", value: "cd"}, %SF{code: "b", value: "ab"}]}
    assert DF.sort(df) == sorted
  end

  test "Record sort" do
    df1 = %DF{tag: "245", ind1: "0", ind2: " ", subfields: [%SF{code: "a", value: "タイトル :"}, %SF{code: "b", value: "関連情報"}]}
    df2 = %DF{tag: "245", ind1: " ", ind2: " ", subfields: [%SF{code: "a", value: "タイトル :"}, %SF{code: "b", value: "関連情報"}]}
    df3 = %DF{tag: "100", ind1: " ", ind2: " ", subfields: [%SF{code: "a", value: "012345"}]}
    cf1 = %CF{tag: "001", value: "12345"}
    l = %Leader{}
    record = %Record{leader: l, data_fields: [df1, df2, df3], control_fields: [cf1]}
    sorted = %Record{leader: l, control_fields: [cf1], data_fields: [df3, df2, df1]}
    assert Record.sort(record) == sorted
  end

  test "~M sigil" do
    record = ~M"""
    FMT	 	BK
    LDR	 	00000cam a22     zi 4500
    001	 	027524410
    24500	 	|6 880-01 |a タイトル / |c 山田, 太郎著.
    260	 	|6 880-02 |a 東京 : |b A出版, |c 2017.2.
    300	 	|a 325p ; |c 21cm.
    SYS	 	027524410
    """
    assert record.__struct__ == Record
  end

end
