defmodule JPMarc.Const do
  @doc """
   Record Separator
  """
  @spec rs()::String.t
  def rs(), do: "\x1d"

  @doc """
   Field Separator
  """
  @spec rs()::String.t
  def fs(), do: "\x1e"

  @doc """
   SubField Separator
  """
  @spec rs()::String.t
  def ss(), do: "\x1f"
end
