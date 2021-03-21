defmodule AwsExampleTest do
  use ExUnit.Case
  doctest AwsExample

  test "greets the world" do
    assert AwsExample.hello() == :world
  end
end
