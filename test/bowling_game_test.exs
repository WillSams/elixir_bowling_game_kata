defmodule BowlingGameTest do
  use ExUnit.Case

  setup do
    {:ok, game: BowlingGame.new()}
  end

  defp roll_many(game, n, pins) do
    Enum.reduce(1..n, game, fn _, g -> BowlingGame.roll(g, pins) end)
  end

  test "gutter game scores 0", %{game: game} do
    game = roll_many(game, 20, 0)
    assert BowlingGame.score(game) == 0
  end

  test "all ones scores 20", %{game: game} do
    game = roll_many(game, 20, 1)
    assert BowlingGame.score(game) == 20
  end

  test "one spare scores 16", %{game: game} do
    game =
      game
      |> BowlingGame.roll(5)
      |> BowlingGame.roll(5)
      |> BowlingGame.roll(3)
      |> roll_many(17, 0)

    assert BowlingGame.score(game) == 16
  end

  test "all spares scores 150", %{game: game} do
    game = roll_many(game, 21, 5)
    assert BowlingGame.score(game) == 150
  end

  test "one strike scores 24", %{game: game} do
    game =
      game
      |> BowlingGame.roll(10)
      |> BowlingGame.roll(3)
      |> BowlingGame.roll(4)
      |> roll_many(16, 0)

    assert BowlingGame.score(game) == 24
  end

  test "perfect game scores 300", %{game: game} do
    game = roll_many(game, 12, 10)
    assert BowlingGame.score(game) == 300
  end
end
