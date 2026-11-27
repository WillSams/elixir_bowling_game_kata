defmodule BowlingGame.CLI do
  @moduledoc """
  Interactive command line front end for `BowlingGame`, started with `mix bowling`.

  Type the number of pins you knocked down. Shortcuts: `x` is a strike, `/` is a
  spare, `new` starts over and `q` quits.
  """

  alias BowlingGame.Scoreboard

  @type outcome :: {:ok | :error, BowlingGame.t(), String.t() | nil} | :quit

  @doc "Plays an interactive game on standard input and output."
  @spec run() :: :ok
  def run do
    IO.puts("Ten-pin bowling. Enter pins knocked down, x (strike), / (spare), new or q.")
    loop(BowlingGame.new())
  end

  @doc """
  Applies one line of user input to the game.

  Returns `{:ok, game, message}` when the input was understood, `{:error, game,
  message}` when it was not (the game is unchanged), or `:quit`.
  """
  @spec handle_input(BowlingGame.t(), String.t()) :: outcome()
  def handle_input(game, input) do
    case input |> String.trim() |> String.downcase() do
      command when command in ["q", "quit", "exit"] -> :quit
      "new" -> {:ok, BowlingGame.new(), "Started a new game."}
      "x" -> roll(game, 10)
      "/" -> spare(game)
      text -> parse_and_roll(game, text)
    end
  end

  defp loop(game) do
    IO.puts("\n" <> Scoreboard.render(game))
    IO.puts("Score: #{BowlingGame.score(game)}")

    if BowlingGame.game_over?(game) do
      IO.puts("Game over! Final score: #{BowlingGame.score(game)}")
    else
      prompt(game)
    end
  end

  defp prompt(game) do
    standing = BowlingGame.pins_standing(game)

    case IO.gets("#{standing} pins standing > ") do
      line when is_binary(line) -> game |> handle_input(line) |> continue(game)
      _eof_or_error -> :ok
    end
  end

  defp continue(:quit, _game), do: :ok

  defp continue({_status, next_game, message}, _game) do
    if message, do: IO.puts(message)
    loop(next_game)
  end

  defp spare(game) do
    case BowlingGame.pins_standing(game) do
      standing when standing in 1..9 -> roll(game, standing)
      _fresh_rack -> {:error, game, "A spare needs a first ball in the frame."}
    end
  end

  defp parse_and_roll(game, text) do
    case Integer.parse(text) do
      {pins, ""} -> roll(game, pins)
      _not_a_number -> {:error, game, "Enter 0-10, x, /, new or q."}
    end
  end

  defp roll(game, pins) do
    case BowlingGame.roll(game, pins) do
      {:ok, next_game} -> {:ok, next_game, nil}
      {:error, reason} -> {:error, game, error_message(reason, game)}
    end
  end

  defp error_message(:invalid_pins, _game), do: "Pins must be a whole number from 0 to 10."
  defp error_message(:game_over, _game), do: "The game is over."

  defp error_message(:too_many_pins, game) do
    "Only #{BowlingGame.pins_standing(game)} pins are standing."
  end
end
