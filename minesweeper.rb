require 'debugger'

class MineSweeper


	def print_board
	end
end

class Board
  attr_reader :bomb_locs, :revealed_board
	def initialize(size, mines)
    @size = size
    @bomb_locs = []
		@hidden_board = generate_board(size, mines)
		@revealed_board = generate_display_board(size)
	end
	def generate_board(size, mines)
		board = []
    row_array = []
    @bomb_locs = []
		size.times do |column|
			row_array[column] = " "
		end
		size.times do |row|
		  board << row_array.dup
    end
    set_mines = 0
    until set_mines == mines
      x = rand(9)
      y = rand(9)
      unless board[x][y] == "b"
        set_mines += 1
        board[x][y] = "b"
        @bomb_locs << [x,y]
      end
    end
    board
	end
  def generate_display_board(size)
    board = []
    row_array = []
    size.times do |column|
      row_array[column] = "*"
    end
    size.times do |row|
      board << row_array.dup
    end
    board
  end
  def bomb?(move)
    @bomb_locs.include?(move)
  end
  def win?
    @bomb_locs.inject(true) do |base, loc|
      base && @revealed_board[loc[0]][loc[1]] == "f"
    end
  end
  def take_turn(move, choice = :reveal)
    update_display_board(move, choice)
    if bomb?(move)
      :lose
    elsif win?
      :win
    else
      :continue
    end
  end
  def outside_board?(dimension)
    dimension < 0 || dimension > @size
  end
  def count_adjacent_mines(move)
    [-1,0,1].product([-1,0,1]).inject(0) do |mine_count, vector|
      #debugger
      row = vector[0]+move[0]
      col = vector[1]+move[1]
      if outside_board?(row) or outside_board?(col)
        mine_count
      elsif @hidden_board[row][col] == "b"
        mine_count += 1
      end
    end
  end
  def reveal_adjacent(move)
    [-1,0,1].product([-1,0,1]).each do |adjacent|
      row = move[0] + adjacent[0]
      p row
      col = move[1] + adjacent[1]
      p col
      next if outside_board?(row) or outside_board?(col)
      next if @revealed_board[row][col] == "f"
      if @revealed_board[row][col] == " "
        update_display_board(@revealed_board[row][col])
      end
    end
  end
  def update_display_board(move, choice = :reveal)
    if choice == :flag
      @revealed_board[move[0]][move[1]] == "f"
    else
      @revealed_board[move[0]][move[1]] = @hidden_board[move[0]][move[1]]
      if @revealed_board[move[0]][move[1]] == " "
        @revealed_board[move[0]][move[1]] = count_adjacent_mines(move).to_s
        reveal_adjacent(move) if @revealed_board[move[0]][move[1]] == "0"
      end
    end
  end
end
