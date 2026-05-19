#!/bin/bash

# The kata script

#############################################
# 1 - Create a new repo                     #
#############################################

# 1.1 - Create the Mix project
mix new elixir_bowling_game_kata && cd elixir_bowling_game_kata

git init .

# 1.2 - Add a .gitignore file to exclude unneeded files
wget -O .gitignore https://raw.githubusercontent.com/github/gitignore/main/Elixir.gitignore

# 1.3 - Set Elixir and Erlang versions via asdf
echo "erlang 26.2
elixir 1.15.8-otp-26" >| .tool-versions
asdf install

# 1.4 - Write a stub BowlingGame module
# 1.4.a - `roll(game, pins)` is called each time the player rolls a ball.
#          The argument is the number of pins knocked down.
# 1.4.b - `score(game)` is called only at the very end of the game.
#          It returns the total score for that game.
echo 'defmodule BowlingGame do
  defstruct rolls: []

  def new(), do: %BowlingGame{}
  def roll(%BowlingGame{} = game, _pins), do: game
  def score(%BowlingGame{}), do: -1
end' >| lib/bowling_game.ex

git add .
git commit -m "Create new bowling kata"

###################################################
# 2 - Write our "0" test for the BowlingGame      #
#     This is our sanity check. =)                #
###################################################

# 2.1 - Write it to fail
echo 'defmodule BowlingGameTest do
  use ExUnit.Case

  # sanity check
  test "BowlingGame module exists" do
    refute Code.ensure_loaded?(BowlingGame)
  end

  # first test
end' >| test/bowling_game_test.exs

mix test # 1 failed, 1 total

# 2.2 - Write it to pass
sed -i "s/refute/assert/" test/bowling_game_test.exs

mix test # 1 passed, 1 total

git add .
git commit -m "Perform the sanity check"

###################################################
# 3 - Write our first test                        #
###################################################

# 3.1 - Write it to fail
sed -e "/first test/r"<(
    echo '
  test "gutter game scores 0" do
    game = BowlingGame.new()
    game = Enum.reduce(1..20, game, fn _, g -> BowlingGame.roll(g, 0) end)
    assert BowlingGame.score(game) == 0
  end

  # second test'
  ) -i -- test/bowling_game_test.exs

mix test # 1 failed, 1 passed, 2 total

# 3.2 - Write it to pass
sed -i "s/do: -1/do: 0/" lib/bowling_game.ex

mix test # 2 passed, 2 total

git add .
git commit -m "Perform the first test"

###################################################
# 4 - Write our second test                       #
###################################################

# 4.1 - Write it to fail
sed -e "/second test/r"<(
    echo '
  test "all ones scores 20" do
    game = BowlingGame.new()
    game = Enum.reduce(1..20, game, fn _, g -> BowlingGame.roll(g, 1) end)
    assert BowlingGame.score(game) == 20
  end

  # third test'
  ) -i -- test/bowling_game_test.exs

mix test # 1 failed, 2 passed, 3 total

# 4.2 - Write it to pass
echo 'defmodule BowlingGame do
  defstruct rolls: []

  def new(), do: %BowlingGame{}

  def roll(%BowlingGame{rolls: rolls} = game, pins) do
    %{game | rolls: rolls ++ [pins]}
  end

  def score(%BowlingGame{rolls: rolls}), do: Enum.sum(rolls)
end' >| lib/bowling_game.ex

mix test # 3 passed, 3 total

git add .
git commit -m "Perform the second test"

###################################################
# 5 - Keep it DRY so let's re-factor              #
###################################################

# 5.1 - Two additions to reduce the duplication:
#       5.1.a - Add a setup/1 callback to create a new game before each test
#       5.1.b - Add a roll_many/3 helper to handle repetitive roll() calls
echo 'defmodule BowlingGameTest do
  use ExUnit.Case

  setup do
    {:ok, game: BowlingGame.new()}
  end

  defp roll_many(game, n, pins) do
    Enum.reduce(1..n, game, fn _, g -> BowlingGame.roll(g, pins) end)
  end

  test "BowlingGame module exists" do
    assert Code.ensure_loaded?(BowlingGame)
  end

  # first test

  test "gutter game scores 0", %{game: game} do
    game = roll_many(game, 20, 0)
    assert BowlingGame.score(game) == 0
  end

  # second test

  test "all ones scores 20", %{game: game} do
    game = roll_many(game, 20, 1)
    assert BowlingGame.score(game) == 20
  end

  # third test
end' >| test/bowling_game_test.exs

mix test # 3 passed, 3 total (no change)

git add .
git commit -m "Refactor the tests"

###################################################
# 6 - Write our third test                        #
###################################################

# 6.1 - Write it to fail
sed -e "/third test/r"<(
    echo '
  test "one spare scores 16", %{game: game} do
    game =
      game
      |> BowlingGame.roll(5)
      |> BowlingGame.roll(5)
      |> BowlingGame.roll(3)
      |> roll_many(17, 0)
    assert BowlingGame.score(game) == 16
  end

  # fourth test'
  ) -i -- test/bowling_game_test.exs

mix test # 1 failed, 3 passed, 4 total

# 6.2 - Write it to pass
#     6.2.a - Enum.sum/1 knows nothing about frames or spares, so we replace
#             it with a recursive scorer that walks the rolls frame by frame.
echo 'defmodule BowlingGame do
  defstruct rolls: []

  def new(), do: %BowlingGame{}

  def roll(%BowlingGame{rolls: rolls} = game, pins) do
    %{game | rolls: rolls ++ [pins]}
  end

  def score(%BowlingGame{rolls: rolls}), do: score_frames(rolls, 0, 0)

  defp score_frames(_, 10, score), do: score

  defp score_frames([a, b | rest], frame, score) when a + b == 10 do
    [c | _] = rest
    score_frames(rest, frame + 1, score + 10 + c)
  end

  defp score_frames([a, b | rest], frame, score) do
    score_frames(rest, frame + 1, score + a + b)
  end
end' >| lib/bowling_game.ex

mix test # 4 passed, 4 total

git add .
git commit -m "Perform the third test"

###################################################
# 7 - Write our fourth test                       #
###################################################

# 7.1 - Write it to fail
sed -e "/fourth test/r"<(
    echo '
  test "one strike scores 24", %{game: game} do
    game =
      game
      |> BowlingGame.roll(10)
      |> BowlingGame.roll(3)
      |> BowlingGame.roll(4)
      |> roll_many(16, 0)
    assert BowlingGame.score(game) == 24
  end

  # fifth test'
  ) -i -- test/bowling_game_test.exs

mix test # 1 failed, 4 passed, 5 total

# 7.2 - Write it to pass
#     7.2.a - A strike consumes only one roll for the frame, so we add
#             a pattern clause that matches 10 before the spare clause.
echo 'defmodule BowlingGame do
  defstruct rolls: []

  def new(), do: %BowlingGame{}

  def roll(%BowlingGame{rolls: rolls} = game, pins) do
    %{game | rolls: rolls ++ [pins]}
  end

  def score(%BowlingGame{rolls: rolls}), do: score_frames(rolls, 0, 0)

  defp score_frames(_, 10, score), do: score

  defp score_frames([10 | rest], frame, score) do
    [a, b | _] = rest
    score_frames(rest, frame + 1, score + 10 + a + b)
  end

  defp score_frames([a, b | rest], frame, score) when a + b == 10 do
    [c | _] = rest
    score_frames(rest, frame + 1, score + 10 + c)
  end

  defp score_frames([a, b | rest], frame, score) do
    score_frames(rest, frame + 1, score + a + b)
  end
end' >| lib/bowling_game.ex

mix test # 5 passed, 5 total

git add .
git commit -m "Perform the fourth test"

###################################################
# 8 - Write our fifth test                        #
###################################################

# 8.1 - Write it to fail
sed -e "/fifth test/r"<(
    echo '
  test "perfect game scores 300", %{game: game} do
    game = roll_many(game, 12, 10)
    assert BowlingGame.score(game) == 299
  end'
  ) -i -- test/bowling_game_test.exs

mix test # 1 failed, 5 passed, 6 total

# 8.2 - Write it to pass
sed -i "s/== 299/== 300/" test/bowling_game_test.exs

mix test # 6 passed, 6 total

git add .
git commit -m "Perform the fifth test"

echo "Finis."
