# coding: utf-8

class Piece
  attr_reader :color, :pos
  attr_accessor :turns_moved, :board

  HORIZONTALS = [[0,1], [0,-1], [1,0], [-1,0]]
  DIAGONALS = [[1,1], [-1,-1], [1,-1], [-1,1]]

  def initialize(color, pos, board)
    @color = color
    @pos = pos
    @board = board
    @turns_moved = 0
  end

  def moves
    raise "Method not implemented"
  end

  def valid_moves(board)
    possible_moves = self.moves
    start_pos = @pos.dup

    possible_moves.select do |end_pos|
      board_copy = board.dup
      board_copy[end_pos] = board_copy[start_pos]
      board_copy[end_pos].update_position(end_pos)
      board_copy[start_pos] = nil
      !board_copy.in_check?(@color)
    end
  end

  def inbound?(pos)
    pos.all? { |dim| dim.between?(0, 7) }
  end

  def inspect
    "Piece: #{self.class} | Color: #{@color} | Pos: #{@pos}"
  end

  def dup
    self.class.new(@color, @pos.dup, @board)
  end

  def update_position(pos)
    @pos = pos
  end
end

class SlidingPiece < Piece
  def initialize(color, pos, board)
    @move_dir
    super
  end

  def moves
    valid_pos = []

    @move_dir.each do |row, col|
      new_pos = @pos.dup
      new_pos[0] += row
      new_pos[1] += col

      while inbound?(new_pos)
        unless @board[new_pos].nil?
          if @board[new_pos].color != @color
            valid_pos << new_pos.dup
          end

          break
        end

        valid_pos << new_pos.dup
        new_pos[0] += row
        new_pos[1] += col
      end
    end

    valid_pos
  end
end

class SteppingPiece < Piece
  def initialize(color, pos, board)
    @move_dir
    super
  end

  def moves
    # return all possible moves before hitting another piece
    valid_pos = []

    @move_dir.each do |row, col|
      new_pos = @pos.dup
      new_pos[0] += row
      new_pos[1] += col

      if inbound?(new_pos)
        unless @board[new_pos].nil?
          valid_pos << new_pos.dup unless @board[new_pos].color == @color
        else
          valid_pos << new_pos.dup
        end
      end
    end

    valid_pos
  end
end

class BlackPawn < Piece
  attr_reader :icon

  def initialize(color, pos, board)
    @move_dir = [[1, 0], [2, 0]]
    @icon = '♟'
    super
  end

  def moves
    valid_pos = []
    unless @turns_moved == 0
      @move_dir = [[1, 0]]
    end

    unless self.pos[1] == 7
      if @board[[pos[0]+1, pos[1]+1]] != nil and @board[[pos[0]+1, pos[1]+1]].color != @color
        valid_pos << [pos[0]+1, pos[1]+1]
      end
    end

    unless self.pos[1] == 0
      if @board[[pos[0]+1, pos[1]-1]] != nil and @board[[pos[0]+1, pos[1]-1]].color != @color
        valid_pos << [pos[0]+1, pos[1]-1]
      end
    end

    @move_dir.each do |row, col|
      new_pos = @pos.dup
      new_pos[0] += row
      new_pos[1] += col

      if inbound?(new_pos)
        valid_pos << new_pos.dup if @board[new_pos].nil? && @board[[@pos[0] + 1, @pos[1]]].nil?
      end
    end

    valid_pos
  end
end

class WhitePawn < Piece
  attr_reader :icon

  def initialize(color, pos, board)
    @move_dir = [[-1, 0], [-2, 0]]
    @icon = '♙'
    super
  end

  def moves
    valid_pos = []
    unless @turns_moved == 0
      @move_dir = [[-1, 0]]
    end

    unless self.pos[1] == 7
      if @board[[pos[0]-1, pos[1]+1]] != nil and @board[[pos[0]-1, pos[1]+1]].color != @color
        valid_pos << [pos[0]-1, pos[1]+1]
      end
    end

    unless self.pos[1] == 0
      if @board[[pos[0]-1, pos[1]-1]] != nil and @board[[pos[0]-1, pos[1]-1]].color != @color
        valid_pos << [pos[0]-1, pos[1]-1]
      end
    end

    @move_dir.each do |row, col|
      new_pos = @pos.dup
      new_pos[0] += row
      new_pos[1] += col

      if inbound?(new_pos)
        valid_pos << new_pos.dup if @board[new_pos].nil? && @board[[@pos[0] - 1, @pos[1]]].nil?
      end
    end

    valid_pos
  end
end

class Queen < SlidingPiece
  attr_reader :icon

  def initialize(color, pos, board)
    super
    @move_dir = HORIZONTALS + DIAGONALS
    @icon = (@color == :white) ? '♕' : '♛'
  end
end

class Bishop < SlidingPiece
  attr_reader :icon

  def initialize(color, pos, board)
    super
    @move_dir = DIAGONALS
    @icon = (@color == :white) ? '♗' : '♝'
  end
end

class Rook < SlidingPiece
  attr_reader :icon

  def initialize(color, pos, board)
    super
    @move_dir = HORIZONTALS
    @icon = (@color == :white) ? '♖' : '♜'
  end
end

class Knight < SteppingPiece
  attr_reader :icon

  def initialize(color, pos, board)
    super
    @move_dir = [[2, 1], [1, 2], [-1, 2], [-2, -1], [-2, 1], [-1, -2], [1, -2], [2, -1]]
    @icon = (@color == :white) ? '♘' : '♞'
  end
end

class King < SteppingPiece
  attr_reader :icon

  def initialize(color, pos, board)
    super
    @move_dir = DIAGONALS + HORIZONTALS
    @icon = (@color == :white) ? '♔' : '♚'
  end
end