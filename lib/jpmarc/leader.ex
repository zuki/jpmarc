defmodule JPMarc.Leader do
  defstruct length: 0, status: "", type: "", level: "", base: 0

  def init(leader) do
    <<length::bytes-size(5), status::bytes-size(1), type::bytes-size(1),
      level::bytes-size(1), _::bytes-size(4), base::bytes-size(5), _::binary>> = leader
    %JPMarc.Leader{length: String.to_integer(length), status: status, type: type, level: level, base: String.to_integer(base)}
  end
end
