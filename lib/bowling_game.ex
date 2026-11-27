defmodule BowlingGame do
  @moduledoc """
  Scores a ten-pin bowling game using the classic Bob Martin kata rules.

  Rolls are validated as they are recorded, and a game can be scored (and
  inspected frame by frame) at any point, not just once it is finished.

  ## Examples

      iex> game =
      ...>   BowlingGame.new()
      ...>   |> BowlingGame.roll!(10)
      ...>   |> BowlingGame.roll!(3)
      ...>   |> BowlingGame.roll!(4)
      iex> BowlingGame.score(game)
      24

  Invalid rolls are rejected instead of corrupting the game:

      iex> BowlingGame.roll(BowlingGame.new(), 11)
      {:error, :invalid_pins}
      iex> game = BowlingGame.roll!(BowlingGame.new(), 7)
      iex> BowlingGame.roll(game, 5)
      {:error, :too_many_pins}
  """

  defstruct rolls: []

  @type t :: %__MODULE__{rolls: [non_neg_integer()]}

  @typedoc """
  One frame of the score card. `score` is the running total after this frame, or
  `nil` while the frame (or the bonus it is waiting for) is still incomplete.
  """
  @type frame :: %{
          number: 1..10,
          rolls: [non_neg_integer()],
          score: non_neg_integer() | nil,
          complete?: boolean()
        }

  @type roll_error :: :game_over | :invalid_pins | :too_many_pins

  @doc "Starts a new game with no rolls."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Records a roll of `pins` knocked down.

  Returns `{:ok, game}`, or `{:error, reason}` where `reason` is:

    * `:game_over` - the game has already finished
    * `:invalid_pins` - `pins` is not an integer from 0 to 10
    * `:too_many_pins` - more pins than are standing for this roll
  """
  @spec roll(t(), term()) :: {:ok, t()} | {:error, roll_error()}
  def roll(%__MODULE__{rolls: rolls} = game, pins) do
    with :ok <- check_not_over(game),
         :ok <- check_pins(pins),
         :ok <- check_standing(game, pins) do
      {:ok, %{game | rolls: rolls ++ [pins]}}
    end
  end

  @doc "Like `roll/2` but returns the game directly and raises `ArgumentError` on an invalid roll."
  @spec roll!(t(), term()) :: t()
  def roll!(game, pins) do
    case roll(game, pins) do
      {:ok, game} -> game
      {:error, reason} -> raise ArgumentError, "cannot roll #{inspect(pins)}: #{reason}"
    end
  end

  @doc """
  The score so far: the running total of every frame that is fully scored.

  A strike or spare is not counted until its bonus rolls have been made, and an
  unfinished game never raises.
  """
  @spec score(t()) :: non_neg_integer()
  def score(%__MODULE__{} = game) do
    last_scored =
      game
      |> frames()
      |> Enum.map(& &1.score)
      |> Enum.reject(&is_nil/1)
      |> List.last()

    last_scored || 0
  end

  @doc "True once all ten frames (including any 10th frame bonus balls) are complete."
  @spec game_over?(t()) :: boolean()
  def game_over?(%__MODULE__{} = game) do
    match?(%{number: 10, complete?: true}, List.last(frames(game)))
  end

  @doc """
  How many pins are standing for the next roll: 10 on a fresh rack, fewer
  mid-frame, and 0 once the game is over.
  """
  @spec pins_standing(t()) :: 0..10
  def pins_standing(%__MODULE__{} = game) do
    case List.last(frames(game)) do
      nil -> 10
      %{number: 10, complete?: true} -> 0
      %{complete?: true} -> 10
      frame -> standing_in(frame)
    end
  end

  @doc """
  Breaks the game into frames, each with its rolls and running total.

  Only frames that have been started are returned.
  """
  @spec frames(t()) :: [frame()]
  def frames(%__MODULE__{rolls: rolls}), do: build_frames(rolls, 1, 0, [])

  # -- validation -------------------------------------------------------------

  defp check_not_over(game) do
    if game_over?(game), do: {:error, :game_over}, else: :ok
  end

  defp check_pins(pins) when is_integer(pins) and pins >= 0 and pins <= 10, do: :ok
  defp check_pins(_pins), do: {:error, :invalid_pins}

  defp check_standing(game, pins) do
    if pins <= pins_standing(game), do: :ok, else: {:error, :too_many_pins}
  end

  # Pins standing for the next roll inside an incomplete frame.
  defp standing_in(%{number: 10, rolls: [10, second]}) when second < 10, do: 10 - second
  defp standing_in(%{number: 10, rolls: [_first, _second]}), do: 10
  defp standing_in(%{rolls: [10]}), do: 10
  defp standing_in(%{rolls: [first]}), do: 10 - first

  # -- framing and scoring ----------------------------------------------------

  defp build_frames([], _number, _total, acc), do: Enum.reverse(acc)

  defp build_frames(rolls, 10, total, acc) do
    tenth = Enum.take(rolls, 3)
    complete? = tenth_complete?(tenth)
    score = if complete?, do: add(total, Enum.sum(tenth), [], 0)

    Enum.reverse([frame(10, tenth, score, complete?) | acc])
  end

  defp build_frames([10 | rest], number, total, acc) do
    score = add(total, 10, rest, 2)
    build_frames(rest, number + 1, score, [frame(number, [10], score, true) | acc])
  end

  defp build_frames([first, second | rest], number, total, acc) do
    base = first + second
    bonus_rolls = if base == 10, do: 1, else: 0
    score = add(total, base, rest, bonus_rolls)

    build_frames(rest, number + 1, score, [frame(number, [first, second], score, true) | acc])
  end

  defp build_frames([first], number, _total, acc) do
    Enum.reverse([frame(number, [first], nil, false) | acc])
  end

  defp tenth_complete?([first, second]), do: first != 10 and first + second < 10
  defp tenth_complete?([_first, _second, _third]), do: true
  defp tenth_complete?(_rolls), do: false

  # Running total after a frame; nil until `needed` bonus rolls exist, and
  # nil forever after once an earlier frame is still waiting on its bonus.
  defp add(nil, _amount, _bonus, _needed), do: nil

  defp add(total, amount, bonus, needed) do
    if length(bonus) >= needed, do: total + amount + Enum.sum(Enum.take(bonus, needed))
  end

  defp frame(number, rolls, score, complete?) do
    %{number: number, rolls: rolls, score: score, complete?: complete?}
  end
end
