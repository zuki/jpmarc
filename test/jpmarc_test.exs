defmodule JPMarcTest do
  use ExUnit.Case

  test "open file" do
    record = JPMarc.parse_file(Path.absname("marc.mrc"))
    assert record != nil
  end
end
