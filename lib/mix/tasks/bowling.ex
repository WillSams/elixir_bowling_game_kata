defmodule Mix.Tasks.Bowling do
  @shortdoc "Play a game of bowling in the terminal"

  @moduledoc """
  Plays an interactive game of ten-pin bowling.

      mix bowling

  Enter the pins knocked down for each roll (`x` for a strike, `/` for a spare).
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args), do: BowlingGame.CLI.run()
end
