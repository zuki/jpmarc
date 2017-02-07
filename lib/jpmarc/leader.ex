defmodule JPMarc.Leader do
  @typedoc """
      Type that represents JPMarc.Leader struct with :length as integer, :status as binary,
      :type of binary, :level as binary and base as integer
  """
  @type t :: %JPMarc.Leader{length: integer, status: binary, type: binary, level: binary, base: integer}
  defstruct length: 0, status: "", type: "", level: "", base: 0
end
