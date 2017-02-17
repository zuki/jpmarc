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
    {control_fields, data_fields} = Enum.split_with(record.fields, &(&1.__struct__ == CF))
    {:ok, [
      records: records,
      record: record,
      leader: record.leader,
      control_fields: control_fields,
      data_fields: data_fields]}
  end

  test "Parse MARC file", %{records: records, record: record} do
    assert length(records) == 2
    assert JPMarc.parse_marc("test/data/test1.mrc") == record
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
    {:ok, org} = File.read("test/data/test1.mrc")
    assert marc == org
  end

  test "Write a MARC as text file", %{record: record} do
    marc_text = "00276nam a2200109zi 4500\n001 123456789012\n003 JTNDL\n005 20170209103923.0\n007 ta\n008 170209s2017    ja ||||g |||| |||||||jpn  \n020    $c 2000円 $z 978-4-123456-01-0\n245 00 $a タイトル : $b 関連情報 / $c 山田太郎 著."
    assert Record.to_text(record) == marc_text
    record1 = ~m"#{marc_text}"
    assert record1 == record
  end

  test "Record sort" do
    df1 = %DF{tag: "245", ind1: "0", ind2: " ", subfields: [%SF{code: "a", value: "タイトル :"}, %SF{code: "b", value: "関連情報"}]}
    df2 = %DF{tag: "245", ind1: " ", ind2: " ", subfields: [%SF{code: "a", value: "タイトル :"}, %SF{code: "b", value: "関連情報"}]}
    df3 = %DF{tag: "100", ind1: " ", ind2: " ", subfields: [%SF{code: "a", value: "012345"}]}
    cf1 = %CF{tag: "001", value: "12345"}
    l = %Leader{}
    record = %Record{leader: l, fields: [df1, df2, df3, cf1]}
    sorted = %Record{leader: l, fields: [cf1, df3, df2, df1]}
    assert Record.sort(record) == sorted
  end

  test "Fields", %{record: record} do
    assert Record.control_field?("001") == true
    assert Record.control_field?("002") == false

    df = %DF{tag: "245", ind1: "0", ind2: "0",
      subfields: [
        %SF{code: "a", value: "タイトル :"},
        %SF{code: "b", value: "関連情報 /"},
        %SF{code: "c", value: "山田太郎 著."},
      ]}

    assert Record.field(record, "001") == %CF{tag: "001", value: "123456789012"}
    assert Record.fields(record, "245") == [df]
    assert Record.field(record, "245") == df
    assert Record.fields(record, "245", "0", "0") == [df]
    assert Record.field(record, "245", "0", "0") == df

    assert Record.field_value(record, "001") == "123456789012"
    assert Record.field_value(record, "245") == "タイトル : 関連情報 / 山田太郎 著."
    assert Record.subfield_value(record, "245") == "タイトル : 関連情報 / 山田太郎 著."
    assert Record.subfield_value(record, "245", :all) == "タイトル : 関連情報 / 山田太郎 著."
    assert Record.subfield_value(record, "245", "a") == "タイトル :"
    assert Record.subfield_value(record, "245", ["a", "b"]) == "タイトル : 関連情報 /"
  end

  test "~m sigil" do
    record1 = ~m"""
    00000cam a22     zi 4500
    001 027524410
    245 00 $6 880-01 $a タイトル / $c 山田, 太郎著.
    260    $6 880-02 $a 東京 : $b A出版, $c 2017.2.
    300    $a 325p ; $c 21cm.
    880 00 $6 245-01/$1 $a タイトル.
    """
    assert record1.__struct__ == Record
    assert Record.subfield_value(record1, "880", "6") == "245-01/$1"

    assert JPMarc.is_leader(~m"00000cam a22     zi 4500")
    assert JPMarc.is_controlfield(~m"001 027524410")
    assert JPMarc.is_datafield(~m"245 00 $6 880-01 $a タイトル / $c 山田, 太郎著.")

    fields = ~m"""
    001 027524410
    245 00 $6 880-01 $a タイトル / $c 山田, 太郎著.
    """

    assert length(fields) == 2
    assert JPMarc.is_controlfield(Enum.at(fields, 0))
    assert JPMarc.is_datafield(Enum.at(fields, 1))

    record2 = ~m"""
    FMT	 	BK
    LDR	 	00000cam a22     zi 4500
    001	 	027524410
    24500	 	|6 880-01 |a タイトル / |c 山田, 太郎著.
    260	 	|6 880-02 |a 東京 : |b A出版, |c 2017.2.
    300	 	|a 325p ; |c 21cm.
    SYS	 	027524410
    """n
    assert record2.__struct__ == Record
    assert Record.subfield_value(record1, "245", ["a", "c"]) == "タイトル / 山田, 太郎著."
  end

  test "Write MARCXML", %{record: record} do
    xml = JPMarc.to_xml(record)
    assert xml == "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<collection xmlns=\"http://www.loc.gov/MARC21/slim\">\n\t<record>\n\t\t<leader>00276nam a2200109zi 4500</leader>\n\t\t<controlfield tag=\"001\">123456789012</controlfield>\n\t\t<controlfield tag=\"003\">JTNDL</controlfield>\n\t\t<controlfield tag=\"005\">20170209103923.0</controlfield>\n\t\t<controlfield tag=\"007\">ta</controlfield>\n\t\t<controlfield tag=\"008\">170209s2017    ja ||||g |||| |||||||jpn  </controlfield>\n\t\t<datafield tag=\"020\">\n\t\t\t<subfield code=\"c\">2000円</subfield>\n\t\t\t<subfield code=\"z\">978-4-123456-01-0</subfield>\n\t\t</datafield>\n\t\t<datafield tag=\"245\">\n\t\t\t<subfield code=\"a\">タイトル :</subfield>\n\t\t\t<subfield code=\"b\">関連情報 /</subfield>\n\t\t\t<subfield code=\"c\">山田太郎 著.</subfield>\n\t\t</datafield>\n\t</record>\n</collection>"
  end

  test "Write JSON", %{record: record} do
    json = JPMarc.to_json(record)
    assert json == "{\"leader\":\"00276nam a2200109zi 4500\",\"fields\":[{\"001\":\"123456789012\"},{\"003\":\"JTNDL\"},{\"005\":\"20170209103923.0\"},{\"007\":\"ta\"},{\"008\":\"170209s2017    ja ||||g |||| |||||||jpn  \"},{\"020\":{\"ind1\":\" \",\"ind2\":\" \",\"subfields\":[{\"c\":\"2000円\"},{\"z\":\"978-4-123456-01-0\"}]}},{\"245\":{\"ind1\":\"0\",\"ind2\":\"0\",\"subfields\":[{\"a\":\"タイトル :\"},{\"b\":\"関連情報 /\"},{\"c\":\"山田太郎 著.\"}]}}]}"
  end

end
