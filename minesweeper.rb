class MineSweeper


	def print_board
	end
end

class Board
	def initialize(size, mines)
		@hidden_board = generate_board(size, mines)
		@revealed_board
	end
	def generate_board(size, mines)
		board = []
    row_array = []
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
      set_mines += 1 unless board[x][y] == "b"
      board[x][y] = "b"
    end
    board
	end
end
