require './chess_pieces'
require 'colorize'

class Board
  attr_accessor :cursor, :highlighted

  def initialize
    @board_state = Array.new(8) { Array.new(8) }
    self.set_board
    @cursor = [6, 0]
    @highlighted = []
  end

  def show_board
    white = true

    puts "   a  b  c  d  e  f  g  h"
    @board_state.each_with_index do |row, i|
      print "#{8 - i} "
      row.each_with_index do |col, j|
        if [i, j] == @cursor
          col.nil? ? print("   ".on_red) : print(" #{col.icon} ".on_red)
          white = !white
        elsif @highlighted.include?([i, j])
          col.nil? ? print("   ".on_yellow) : print(" #{col.icon} ".on_yellow)
          white = !white
        else
          if white
            col.nil? ? print("   ".on_blue) : print(" #{col.icon} ".on_blue)
            white = !white
          else
            col.nil? ? print("   ") : print(" #{col.icon} ")
            white = !white
          end
        end
      end
      white = !white
      puts " #{8 - i}"
    end
    puts "   a  b  c  d  e  f  g  h"
    puts "\nUse wsad to move, q to quit and save"
    puts "Spacebar to grab/drop pieces."
  end

  def set_board
    @board_state[1].each_with_index do |place, i|
      self[[1, i]] = BlackPawn.new(:black, [1, i], self)
    end

    @board_state[6].each_with_index do |place, i|
      self[[6,i]] = WhitePawn.new(:white, [6, i], self)
    end

    self[[0, 0]] = Rook.new(:black, [0, 0], self)
    self[[0, 7]] = Rook.new(:black, [0, 7], self)
    self[[7, 0]] = Rook.new(:white, [7, 0], self)
    self[[7, 7]] = Rook.new(:white, [7, 7], self)

    self[[0, 1]] = Knight.new(:black, [0, 1], self)
    self[[0, 6]] = Knight.new(:black, [0, 6], self)
    self[[7, 1]] = Knight.new(:white, [7, 1], self)
    self[[7, 6]] = Knight.new(:white, [7, 6], self)

    self[[0, 2]] = Bishop.new(:black, [0, 2], self)
    self[[0, 5]] = Bishop.new(:black, [0, 5], self)
    self[[7, 2]] = Bishop.new(:white, [7, 2], self)
    self[[7, 5]] = Bishop.new(:white, [7, 5], self)

    self[[0, 3]] = Queen.new(:black, [0, 3], self)
    self[[7, 3]] = Queen.new(:white, [7, 3], self)

    self[[0, 4]] = King.new(:black, [0, 4], self)
    self[[7, 4]] = King.new(:white, [7, 4], self)
  end

  def in_check?(color)
    opposing_color = color == :white ? :black : :white
    opposing_pieces = get_pieces(opposing_color)
    opposing_pieces.each do |piece|
      piece_moves = piece.moves
      return true if piece_moves.include?(find_king(color))
    end

    false
  end

  def get_pieces(color)
    pieces = []

    @board_state.each do |row|
      row.each do |piece|
        next if piece.nil?
        pieces << piece if piece.color == color
      end
    end

    pieces
  end

  def score(color)
    values = { BlackPawn => 1, WhitePawn => 1, Knight => 3, Bishop => 3, Rook => 5, Queen => 9, King => 400 }
    pieces = get_pieces(color)
    enemy_pieces = get_pieces(color == :white ? :black : :white)
    score = 0

    pieces.each do |piece|
      score += values[piece.class]
    end

    enemy_pieces.each do |piece|
      score -= values[piece.class]
    end

    score
  end

  def find_king(color)
    @board_state.each do |row|
      row.each do |piece|
        next if piece.nil? or piece.color != color
        return piece.pos if piece.is_a?(King)
      end
    end
  end

  def move(start, finish)
    raise InvalidMoveError if self[start].nil?

    possible_moves = self[start].valid_moves(self)
    raise InvalidMoveError unless possible_moves.include?(finish)

    self[finish] = self[start]
    self[start] = nil
    self[finish].update_position(finish)
    self[finish].turns_moved += 1
  end

  def checkmate?(color)
    pieces_left = get_pieces(color)

    pieces_left.each do |piece|
      return false if !piece.valid_moves(self).empty?
    end

    true
  end

  def []=(pos, piece)
    @board_state[pos[0]][pos[1]] = piece
  end

  def [](pos)
    @board_state[pos[0]][pos[1]]
  end

  def dup
    new_board = Board.new

    @board_state.each_with_index do |row, i|
      row.each_with_index do |piece, j|
        unless piece.nil?
          new_board[[i, j]] = piece.dup
          new_board[[i, j]].board = new_board
        else
          new_board[[i, j]] = nil
        end
      end
    end
    new_board
  end
end