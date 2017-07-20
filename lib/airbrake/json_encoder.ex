alias Airbrake.JSONEncoder

defprotocol Airbrake.JSONEncoder do
  @fallback_to_any true

  def encode(value)
end

defimpl Airbrake.JSONEncoder, for: Tuple do
  def encode(tuple) do
    items =
      tuple
      |> Tuple.to_list
      |> Enum.map(&JSONEncoder.encode/1)
      |> Enum.map(&escape/1)
      |> Enum.join(", ")

    "\"{#{items}}\""
  end

  defp escape(string) do
    String.replace(string, "\"", "\\\"")
  end
end

defimpl Airbrake.JSONEncoder, for: Map do
  defp encode_name(value) when is_binary(value) do
    value
  end

  defp encode_name(value) do
    case String.Chars.impl_for(value) do
      nil ->
        raise "expected a String.Chars encodable value, got: #{inspect(value)}"
      impl ->
        impl.to_string(value)
    end
  end

  def encode(map) when map_size(map) < 1, do: "{}"
  def encode(map) do
    fun = &[?,, JSONEncoder.encode(encode_name(&1)), ?:,
            JSONEncoder.encode(:maps.get(&1, map)) | &2]
    "{#{tl(:lists.foldl(fun, [], :maps.keys(map)))}}"
  end
end

defimpl Airbrake.JSONEncoder, for: List do
  def encode(list) do
    fun = &[?,, JSONEncoder.encode(&1) | &2]
    "[#{tl(:lists.foldr(fun, [], list))}]"
  end
end

defimpl Airbrake.JSONEncoder, for: Any do
  defp failed_encoding(value) do
    Poison.encode!(inspect(value))
  end

  def encode(%{__struct__: struct_name} = struct) do
    Map.from_struct(struct)
    |> Map.put("__struct__", struct_name)
    |> JSONEncoder.Map.encode
  end
  def encode(value) do
    try do
      Poison.encode!(value)
    rescue _ -> failed_encoding(value)
    catch _ -> failed_encoding(value)
    end
  end
end
