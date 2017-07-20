defmodule SomeStruct do
  defstruct [:data]
end

defmodule Airbrake.JSONEncoderTest do
  use ExUnit.Case
  alias Airbrake.JSONEncoder

  test "encoding various types" do
    assert "{\"b\":\"{2, 3}\",\"a\":\"#{inspect(self())}\"}" ==
      JSONEncoder.encode(%{ :a => self(), "b" => {2, 3}})
    assert "{\"__struct__\":\"Elixir.SomeStruct\",\"data\":\"test\"}" ==
      JSONEncoder.encode(%SomeStruct{data: "test"})
    assert "\"{\\\"abc\\\", \\\"#PID<0.209.0>\\\", 123}\"" ==
      JSONEncoder.encode({"abc", self(), 123})
  end
end
