require 'debugger'
require 'yaml'

class MineSweeper
  def initialize
    @smile = ":|"
    start_menu
  end
  def start_menu
    puts "Would you like to start a new game or load an existing game?"
    puts "Type 'load' to load, 'start' to start a new game, 'quit' to quit"
    puts "Or type 'scores' to view the high scores board"
    command = gets.downcase.chomp
    case command
    when "load"
      load
      play
    when "start"
      new_game
      play
    when "scores"
      scores_prompt
    when "quit"
      puts "Byebye loser."
    else
      start_menu
    end
  end
  def load
    saved_state = File.read("save.txt")
    @board = YAML::load(saved_state)
    @board.add_start_interval
  end
  def new_game
    @board = setup
  end
  def setup
    puts "How many squares long and wide will your board be?"
    size = gets.chomp.to_i
    puts "How many mines do you want on the board?"
    mines = gets.chomp.to_i
    Board.new(size, mines)
  end

  def play(play_status = :continue)
    @smile = "B)" if play_status == :win
    @smile = ":(" if play_status == :lose
    print_board
    case play_status
    when :continue
      play_status = get_command
      play(play_status)
    when :lose
      puts "You lost!"
    when :win
      puts "Congrats, you won!"
      @board.add_end_interval
      update_leader_board (@board.calculate_time)
    when :save
      save
    when :load
    end
    start_menu if play_status == :lose || play_status == :win
  end
  def update_leader_board (total_time)
    puts "What's your name?"
    name = gets.chomp
    score = HighScoreEntry.new(name, total_time, @board.size, @board.mines)
    if File.exist?("high_scores.txt")
      saved_scores = File.read("high_scores.txt")
      high_scores = YAML::load(saved_scores)
    else
      high_scores = HighScoreList.new
    end
    high_scores.add_score(score)

    File.open("high_scores.txt", "w") do |f|
      f.puts high_scores.to_yaml
    end
  end
  def scores_prompt
    puts "Dimension of board for high scores list?"
    size = gets.chomp.to_i
    puts "Number of mines for high scores list?"
    mines = gets.chomp.to_i
    print_leader_board(size, mines)
    start_menu
  end
  def print_leader_board(size, mines)
    if File.exist?("high_scores.txt")
      saved_scores = File.read("high_scores.txt")
      high_scores = YAML::load(saved_scores)
      #debugger
      puts "High Scores for #{size} dimension and #{mines} mines:"
      high_scores.get_high_scores(size, mines).each_with_index do |score, index|
        puts "#{index+1}: #{score.name}, #{score.time} seconds"
      end
    else
      puts "No high scores saved!"
    end
  end

  def save
    @board.add_end_interval
    File.open("save.txt", "w") do |f|
      f.puts @board.to_yaml
    end
  end

  def get_command
    puts "\nNot dead yet! What's your move?"
    puts "format: '3,4' (y-coordinate first)"
    puts "or '5,7,f' to place a flag."
    puts "If you would like to continue another time, put 's'"
    move_input = gets.chomp.split(",")
    choice = :reveal
    if move_input.length == 3 && move_input[2].downcase == "f"
      choice = :flag
    end
    if move_input[0].downcase == "s"
      :save
    else
      move = move_input[0..1].map { |coordinate| coordinate.to_i }
      @board.take_turn(move, choice)
    end
  end

	def print_board
    top = (0...@board.revealed_board.length).to_a
    top.map!{|index| index.to_s.ljust(3) }
    top_str = "#{@smile}   #{top.join}"
    puts top_str
    puts "_" * top_str.length
    @board.revealed_board.each_with_index do |row, index|
      puts "#{index.to_s.ljust(3)} |#{row.join('  ')}"
    end
	end
end

class Board
  attr_reader :revealed_board, :size, :mines
	def initialize(size, mines)
    @start_times = [Time.now]
    @end_times = []
    @size = size
    @bomb_locs = []
    @mines = mines
		@hidden_board = generate_board(size, mines)
		@revealed_board = generate_display_board(size)
	end
  def add_start_interval
    @start_times << Time.now
  end
  def add_end_interval
    @end_times << Time.now
  end
  def calculate_time
    differences = []
    @end_times.each_with_index do |end_time, index|
      differences << end_time - @start_times[index]
    end
    differences.inject(:+)
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
      x = rand(size)
      y = rand(size)
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
    flags = 0
    @revealed_board.each_with_index do |row, row_index|
      row.each_with_index do |square, col_index|
        flags += 1 if square == "f"
      end
    end
    if flags == @bomb_locs.length
      @bomb_locs.inject(true) do |base, loc|
        base && @revealed_board[loc[0]][loc[1]] == "f"
      end
    else
      false
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
class HighScoreEntry
  attr_reader :name, :time, :size, :mines
  def initialize(name, time, size, mines)
    @name = name
    @time = time
    @size = size
    @mines = mines
  end
end
class HighScoreList
  attr_reader :high_scores
  def initialize
    @high_scores = []
  end
  def add_score(entry)
    @high_scores << entry
  end
  def order_list
    @high_scores.sort! { |a, b| a.time <=> b.time }
  end
  def get_high_scores(size, mines)
    order_list
    @high_scores.select do |score|
      score.size == size && score.mines == mines
    end
  end
end
game = MineSweeper.new