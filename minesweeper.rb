require 'debugger'

class MineSweeper
  def initialize
    @board = setup
    play
  end

  def setup
    puts "How many squares long and wide will your board be?"
    size = gets.chomp.to_i
    puts "How many mines do you want on the board?"
    mines = gets.chomp.to_i
    Board.new(size, mines)
  end

  def play(play_status = :continue)
    print_board
    case play_status
    when :continue
      play_status = get_move
      play(play_status)
    when :lose
      puts "You lost!"
    when :win
      puts "Congrats, you won!"
    end
  end

  def get_move
    puts "Not dead yet! What's your move?"
    puts "format: '3,4' (y-coordinate first)"
    puts "or '5,7,f' to place a flag."
    move_input = gets.chomp.split(",")
    choice = :reveal
    if move_input.length == 3 && move_input[2].downcase == "f"
      choice = :flag
    end
    move = move_input[0..1].map { |coordinate| coordinate.to_i }
    @board.take_turn(move, choice)
  end

	def print_board
    puts "  #{(0...@board.revealed_board.length).to_a.join(' ')}"
    @board.revealed_board.each_with_index do |row, index|
      puts "#{index} #{row.join(' ')}"
    end
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
    if choice == :reveal && bomb?(move)
      :lose
    elsif win?
      :win
    else
      :continue
    end
  end
  def outside_board?(dimension)
    dimension < 0 || dimension > @size-1
  end
  def count_adjacent_mines(move)
    mine_count = 0
    [-1,0,1].product([-1,0,1]).each do |vector|
      #debugger
      row = vector[0]+move[0]
      col = vector[1]+move[1]
      next if outside_board?(row) or outside_board?(col)
        mine_count
      mine_count += 1 if @hidden_board[row][col] == "b"
    end
    mine_count
  end
  def reveal_adjacent(move)
    [-1,0,1].product([-1,0,1]).each do |adjacent|
      row = move[0] + adjacent[0]
      col = move[1] + adjacent[1]
      next if outside_board?(row) or outside_board?(col)
      next if @revealed_board[row][col] == "f"
      if @revealed_board[row][col] == "*"
        update_display_board([row, col])
      end
    end
  end
  def update_display_board(move, choice = :reveal)
    if choice == :flag && @revealed_board[move[0]][move[1]] == "*"
      @revealed_board[move[0]][move[1]] = "f"
    else
      @revealed_board[move[0]][move[1]] = @hidden_board[move[0]][move[1]]
      if @revealed_board[move[0]][move[1]] == " "
        @revealed_board[move[0]][move[1]] = count_adjacent_mines(move).to_s
        reveal_adjacent(move) if @revealed_board[move[0]][move[1]] == "0"
      end
    end
  end
end
game = MineSweeper.new