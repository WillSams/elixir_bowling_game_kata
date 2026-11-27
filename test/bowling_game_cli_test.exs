defmodule BowlingGame.CLITest do
  use ExUnit.Case, async: true

  alias BowlingGame.CLI

  setup do
    {:ok, game: BowlingGame.new()}
  end

  test "a number rolls that many pins", %{game: game} do
    assert {:ok, %BowlingGame{rolls: [5]}, nil} = CLI.handle_input(game, "5\n")
  end

  test "x is a strike", %{game: game} do
    assert {:ok, %BowlingGame{rolls: [10]}, nil} = CLI.handle_input(game, "X")
  end

  test "/ knocks down the remaining pins", %{game: game} do
    game = BowlingGame.roll!(game, 7)
    assert {:ok, %BowlingGame{rolls: [7, 3]}, nil} = CLI.handle_input(game, "/")
  end

  test "/ is rejected on a fresh rack", %{game: game} do
    assert {:error, ^game, message} = CLI.handle_input(game, "/")
    assert message =~ "spare"
  end

  test "bad input leaves the game unchanged", %{game: game} do
    assert {:error, ^game, _message} = CLI.handle_input(game, "banana")
    assert {:error, ^game, _message} = CLI.handle_input(game, "11")
    assert {:error, ^game, _message} = CLI.handle_input(game, "-2")
    assert {:error, ^game, _message} = CLI.handle_input(game, "")
  end

  test "reports how many pins are actually standing", %{game: game} do
    game = BowlingGame.roll!(game, 7)
    assert {:error, ^game, message} = CLI.handle_input(game, "5")
    assert message =~ "3 pins"
  end

  test "new starts over and q quits", %{game: game} do
    game = BowlingGame.roll!(game, 7)
    assert {:ok, %BowlingGame{rolls: []}, _message} = CLI.handle_input(game, "new")
    assert CLI.handle_input(game, "q") == :quit
    assert CLI.handle_input(game, "quit") == :quit
  end
end
