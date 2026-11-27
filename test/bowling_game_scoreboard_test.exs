defmodule BowlingGame.ScoreboardTest do
  use ExUnit.Case, async: true

  alias BowlingGame.Scoreboard

  defp play(pins_list) do
    Enum.reduce(pins_list, BowlingGame.new(), fn pins, game -> BowlingGame.roll!(game, pins) end)
  end

  test "renders an empty card for a new game" do
    lines = BowlingGame.new() |> Scoreboard.render() |> String.split("\n")

    assert length(lines) == 6
    assert Enum.all?(lines, &(String.length(&1) == String.length(hd(lines))))
  end

  test "marks strikes, spares and misses" do
    game = play([10, 7, 3, 9, 0])
    [_, _, _, marks, scores, _] = game |> Scoreboard.render() |> String.split("\n")

    assert marks =~ "X"
    assert marks =~ "7 /"
    assert marks =~ "9 -"
    assert scores =~ "20"
    assert scores =~ "39"
    assert scores =~ "48"
  end

  test "renders a perfect game" do
    game = play(List.duplicate(10, 12))
    [_, _, _, marks, scores, _] = game |> Scoreboard.render() |> String.split("\n")

    assert marks =~ "X X X"
    assert scores =~ "300"
  end

  test "renders 10th frame bonus balls" do
    game = play(List.duplicate(0, 18) ++ [5, 5, 10])
    [_, _, _, marks, _, _] = game |> Scoreboard.render() |> String.split("\n")

    assert marks =~ "5 / X"
  end

  test "every row is the same width" do
    game = play(List.duplicate(10, 12))
    widths = game |> Scoreboard.render() |> String.split("\n") |> Enum.map(&String.length/1)

    assert widths |> Enum.uniq() |> length() == 1
  end
end
