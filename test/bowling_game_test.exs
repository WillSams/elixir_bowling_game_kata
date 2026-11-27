defmodule BowlingGameTest do
  use ExUnit.Case, async: true

  doctest BowlingGame

  setup do
    {:ok, game: BowlingGame.new()}
  end

  defp roll_many(game, n, pins) do
    Enum.reduce(1..n, game, fn _, g -> BowlingGame.roll!(g, pins) end)
  end

  defp roll_all(game, pins_list) do
    Enum.reduce(pins_list, game, fn pins, g -> BowlingGame.roll!(g, pins) end)
  end

  describe "scoring (the original kata)" do
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
        |> BowlingGame.roll!(5)
        |> BowlingGame.roll!(5)
        |> BowlingGame.roll!(3)
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
        |> BowlingGame.roll!(10)
        |> BowlingGame.roll!(3)
        |> BowlingGame.roll!(4)
        |> roll_many(16, 0)

      assert BowlingGame.score(game) == 24
    end

    test "perfect game scores 300", %{game: game} do
      game = roll_many(game, 12, 10)
      assert BowlingGame.score(game) == 300
    end
  end

  describe "scoring an unfinished game" do
    test "a new game scores 0", %{game: game} do
      assert BowlingGame.score(game) == 0
    end

    test "a lone strike does not crash and scores nothing yet", %{game: game} do
      game = BowlingGame.roll!(game, 10)
      assert BowlingGame.score(game) == 0
    end

    test "a strike is scored once both bonus rolls are in", %{game: game} do
      game = roll_all(game, [10, 3])
      assert BowlingGame.score(game) == 0

      game = BowlingGame.roll!(game, 4)
      assert BowlingGame.score(game) == 24
    end

    test "a spare is scored once the bonus roll is in", %{game: game} do
      game = roll_all(game, [5, 5])
      assert BowlingGame.score(game) == 0

      game = BowlingGame.roll!(game, 3)
      assert BowlingGame.score(game) == 13
    end
  end

  describe "frames/1" do
    test "a new game has no frames", %{game: game} do
      assert BowlingGame.frames(game) == []
    end

    test "reports rolls, running totals and pending frames", %{game: game} do
      game = roll_all(game, [10, 7, 3, 9])

      assert BowlingGame.frames(game) == [
               %{number: 1, rolls: [10], score: 20, complete?: true},
               %{number: 2, rolls: [7, 3], score: 39, complete?: true},
               %{number: 3, rolls: [9], score: nil, complete?: false}
             ]
    end

    test "a strike followed by one roll is still pending", %{game: game} do
      game = roll_all(game, [10, 3])

      assert BowlingGame.frames(game) == [
               %{number: 1, rolls: [10], score: nil, complete?: true},
               %{number: 2, rolls: [3], score: nil, complete?: false}
             ]
    end

    test "a perfect game has ten frames with running totals of 30, 60, ... 300", %{game: game} do
      frames = game |> roll_many(12, 10) |> BowlingGame.frames()

      assert Enum.map(frames, & &1.score) == Enum.map(1..10, &(&1 * 30))
      assert List.last(frames).rolls == [10, 10, 10]
    end
  end

  describe "game_over?/1" do
    test "is false until the last roll", %{game: game} do
      refute BowlingGame.game_over?(game)
      refute game |> roll_many(19, 0) |> BowlingGame.game_over?()
      assert game |> roll_many(20, 0) |> BowlingGame.game_over?()
    end

    test "waits for the 10th frame bonus rolls", %{game: game} do
      refute game |> roll_many(11, 10) |> BowlingGame.game_over?()
      assert game |> roll_many(12, 10) |> BowlingGame.game_over?()

      spare_tenth = game |> roll_many(18, 0) |> roll_all([5, 5])
      refute BowlingGame.game_over?(spare_tenth)
      assert spare_tenth |> BowlingGame.roll!(7) |> BowlingGame.game_over?()
    end
  end

  describe "roll/2 validation" do
    test "returns {:ok, game} for a valid roll", %{game: game} do
      assert {:ok, %BowlingGame{rolls: [4]}} = BowlingGame.roll(game, 4)
    end

    test "rejects pins that are not an integer from 0 to 10", %{game: game} do
      assert BowlingGame.roll(game, -1) == {:error, :invalid_pins}
      assert BowlingGame.roll(game, 11) == {:error, :invalid_pins}
      assert BowlingGame.roll(game, 5.0) == {:error, :invalid_pins}
      assert BowlingGame.roll(game, "5") == {:error, :invalid_pins}
      assert BowlingGame.roll(game, nil) == {:error, :invalid_pins}
    end

    test "rejects more pins than are standing in a frame", %{game: game} do
      game = BowlingGame.roll!(game, 6)
      assert BowlingGame.pins_standing(game) == 4
      assert BowlingGame.roll(game, 5) == {:error, :too_many_pins}
      assert {:ok, _game} = BowlingGame.roll(game, 4)
    end

    test "rejects any roll once the game is over", %{game: game} do
      game = roll_many(game, 20, 0)
      assert BowlingGame.roll(game, 0) == {:error, :game_over}
      assert BowlingGame.pins_standing(game) == 0
    end

    test "roll!/2 raises on an invalid roll", %{game: game} do
      assert_raise ArgumentError, ~r/invalid_pins/, fn -> BowlingGame.roll!(game, 12) end
    end
  end

  describe "10th frame rules" do
    setup %{game: game} do
      {:ok, nine_frames: roll_many(game, 18, 0)}
    end

    test "a strike gives two bonus balls on a fresh rack", %{nine_frames: game} do
      game = roll_all(game, [10, 10, 10])
      assert BowlingGame.score(game) == 30
      assert BowlingGame.game_over?(game)
      assert BowlingGame.roll(game, 1) == {:error, :game_over}
    end

    test "after a strike and a miss only the remaining pins are standing", %{nine_frames: game} do
      game = roll_all(game, [10, 3])
      assert BowlingGame.pins_standing(game) == 7
      assert BowlingGame.roll(game, 8) == {:error, :too_many_pins}
      assert game |> BowlingGame.roll!(7) |> BowlingGame.score() == 20
    end

    test "a spare gives one bonus ball on a fresh rack", %{nine_frames: game} do
      game = roll_all(game, [5, 5])
      assert BowlingGame.pins_standing(game) == 10
      assert game |> BowlingGame.roll!(10) |> BowlingGame.score() == 20
      assert BowlingGame.roll(game, 11) == {:error, :invalid_pins}
    end

    test "an open frame ends the game after two balls", %{nine_frames: game} do
      game = roll_all(game, [3, 4])
      assert BowlingGame.game_over?(game)
      assert BowlingGame.score(game) == 7
    end
  end
end
