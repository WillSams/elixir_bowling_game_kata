defmodule BowlingGamePropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  # Raw numbers are clamped to the pins standing, so every sequence plays out as a
  # legal game; 21 rolls is always enough to finish one.
  defp raw_rolls do
    list_of(frequency([{3, constant(10)}, {7, integer(0..10)}]), length: 21)
  end

  defp next_roll(game, raw) do
    if BowlingGame.game_over?(game) do
      game
    else
      BowlingGame.roll!(game, min(raw, BowlingGame.pins_standing(game)))
    end
  end

  defp play(raw_rolls) do
    Enum.reduce(raw_rolls, BowlingGame.new(), fn raw, game -> next_roll(game, raw) end)
  end

  defp scores_after_each_roll(raw_rolls) do
    {scores, _game} =
      Enum.map_reduce(raw_rolls, BowlingGame.new(), fn raw, game ->
        game = next_roll(game, raw)
        {BowlingGame.score(game), game}
      end)

    scores
  end

  # The kata's original recursive scorer, kept here as an oracle for finished games.
  defp reference_score(rolls), do: reference(rolls, 0, 0)

  defp reference(_rolls, 10, score), do: score

  defp reference([10 | rest], frame, score) do
    [a, b | _] = rest
    reference(rest, frame + 1, score + 10 + a + b)
  end

  defp reference([a, b | rest], frame, score) when a + b == 10 do
    [c | _] = rest
    reference(rest, frame + 1, score + 10 + c)
  end

  defp reference([a, b | rest], frame, score), do: reference(rest, frame + 1, score + a + b)

  property "a finished game scores 0..300 and agrees with the reference scorer" do
    check all raw <- raw_rolls() do
      game = play(raw)

      assert BowlingGame.game_over?(game)
      assert BowlingGame.score(game) in 0..300
      assert BowlingGame.score(game) == reference_score(game.rolls)
    end
  end

  property "the score never decreases as rolls are added" do
    check all raw <- raw_rolls() do
      scores = scores_after_each_roll(raw)
      assert scores == Enum.sort(scores)
    end
  end

  property "frames account for every roll exactly once" do
    check all raw <- raw_rolls(), taken <- integer(0..21) do
      game = play(Enum.take(raw, taken))
      assert Enum.flat_map(BowlingGame.frames(game), & &1.rolls) == game.rolls
    end
  end

  property "rolling more pins than are standing is rejected" do
    check all raw <- raw_rolls(), taken <- integer(0..21) do
      game = play(Enum.take(raw, taken))
      standing = BowlingGame.pins_standing(game)

      expected =
        cond do
          BowlingGame.game_over?(game) -> {:error, :game_over}
          standing == 10 -> {:error, :invalid_pins}
          true -> {:error, :too_many_pins}
        end

      assert BowlingGame.roll(game, standing + 1) == expected
    end
  end
end
