defmodule BowlingGame do
  @moduledoc """
  Scores a ten-pin bowling game using the classic Bob Martin kata rules.
  """

  defstruct rolls: []

  def new(), do: %BowlingGame{}

  def roll(%BowlingGame{rolls: rolls} = game, pins) do
    %{game | rolls: rolls ++ [pins]}
  end

  def score(%BowlingGame{rolls: rolls}) do
    score_frames(rolls, 0, 0)
  end

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
end
