defmodule BowlingGame.Scoreboard do
  @moduledoc """
  Renders a `BowlingGame` as a classic bowling score card.

      +-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+
      |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |  10   |
      +-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+
      |   X | 7 / | 9 - |     |     |     |     |     |     |       |
      | 20  | 39  | 48  |     |     |     |     |     |     |       |
      +-----+-----+-----+-----+-----+-----+-----+-----+-----+-------+

  `X` is a strike, `/` a spare and `-` a miss.
  """

  @doc "Renders the score card as a multi-line string."
  @spec render(BowlingGame.t()) :: String.t()
  def render(%BowlingGame{} = game) do
    frames = BowlingGame.frames(game)
    slots = for number <- 1..10, do: {number, Enum.at(frames, number - 1)}

    Enum.join(
      [
        border(),
        row(slots, fn {number, _frame} -> center(Integer.to_string(number), number) end),
        border(),
        row(slots, &marks_cell/1),
        row(slots, &score_cell/1),
        border()
      ],
      "\n"
    )
  end

  defp border do
    "+" <> Enum.map_join(1..10, "+", &String.duplicate("-", width(&1))) <> "+"
  end

  defp row(slots, cell_fun) do
    "|" <> Enum.map_join(slots, "|", cell_fun) <> "|"
  end

  defp width(10), do: 7
  defp width(_number), do: 5

  defp boxes_per_frame(10), do: 3
  defp boxes_per_frame(_number), do: 2

  defp marks_cell({number, nil}), do: center("", number)

  defp marks_cell({number, %{rolls: rolls}}) do
    rolls |> marks() |> boxes(number) |> Enum.join(" ") |> center(number)
  end

  defp score_cell({number, %{score: score}}) when is_integer(score) do
    center(Integer.to_string(score), number)
  end

  defp score_cell({number, _frame}), do: center("", number)

  # Turns pins into score card symbols, tracking how many pins are standing so a
  # roll that clears the rack is a spare (or a strike on a fresh rack).
  defp marks(rolls), do: marks(rolls, 10, [])

  defp marks([], _standing, acc), do: Enum.reverse(acc)

  defp marks([pins | rest], standing, acc) do
    {mark, next_standing} =
      cond do
        pins == 10 and standing == 10 -> {"X", 10}
        pins == standing -> {"/", 10}
        pins == 0 -> {"-", standing}
        true -> {Integer.to_string(pins), standing - pins}
      end

    marks(rest, next_standing, [mark | acc])
  end

  # A strike in frames 1-9 sits in the second box, as on a paper score card.
  defp boxes(["X"], number) when number < 10, do: [" ", "X"]
  defp boxes(marks, number), do: marks ++ List.duplicate(" ", boxes_per_frame(number) - length(marks))

  defp center(text, number) do
    padding = width(number) - String.length(text)
    left = div(padding, 2)

    text
    |> String.pad_leading(String.length(text) + left)
    |> String.pad_trailing(width(number))
  end
end
