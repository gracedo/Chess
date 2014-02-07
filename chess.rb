require './chess_pieces'
require './chessboard'
require 'colorize'
require 'io/console'
require 'yaml'

class InvalidMoveError < StandardError
  attr_reader :message

  def initialize
    @message = "invalid move!"
  end
end

class Game
  attr_accessor :board, :player1, :player2, :curr_player
  def initialize
    @board = Board.new
    @player1 = HumanPlayer.new(:white, @board)
    @player2 = HumanPlayer.new(:black, @board)
    @curr_player = @player1
    @piece_to_move = nil
  end

  def play
    puts "Would you like to load a game? (y/n)"
    ans = gets.chomp!.downcase.split('')
    if ans[0] == 'y'
      puts "Enter filename:"
      filename = gets.chomp!
      contents = File.read(filename)
      saved_game = YAML::load(contents)
      @board = saved_game.board
      @player1 = saved_game.player1
      @player2 = saved_game.player2
      @curr_player = saved_game.curr_player
    else
      puts "Enter Player1's name: "
      @player1.name = gets.chomp!
      puts "Enter Player2's name: "
      @player2.name = gets.chomp!
    end

    until @board.checkmate?(@curr_player.color)
      begin
        if @curr_player.is_a?(ComputerPlayer)
          @curr_player.play_turn
          @curr_player = @curr_player == @player1 ? @player2 : @player1
        else
          navigate_and_select
        end
        redraw_board
      rescue StandardError => e
        p e.message
        return
      end
    end

    system 'clear'
    @board.show_board

    winner = @curr_player == @player1 ? @player2 : @player1
    puts "#{winner.name} wins!"
  end

  def navigate_and_select
    redraw_board
    puts "#{@curr_player.name}'s Turn"
    puts "CHECK!" if @board.in_check?(@curr_player.color)
    char = nil

    until /[wsadq\s]/i =~ char
      begin
        char = STDIN.getch

        if char == 'w'
          move(:up)
        elsif char == 'a'
          move(:left)
        elsif char == 's'
          move(:down)
        elsif char == 'd'
          move(:right)
        elsif char == ' '
          if !@piece_to_move.nil?
            @curr_player.play_turn(@piece_to_move, @board.cursor)
            @curr_player = @curr_player == @player1 ? @player2 : @player1
            @piece_to_move = nil
            @board.highlighted = []
          elsif !@board[@board.cursor].nil?
            @piece_to_move = @board.cursor
            @board.highlighted = @board[@piece_to_move].valid_moves(@board)
          end
        elsif char == 'q'
          File.open(save_as, 'w') { |f| f.puts self.to_yaml }
        end

      rescue InvalidMoveError => e
        puts e.message
        @piece_to_move = nil
        retry
      end
    end
  end

  def redraw_board
    system 'clear'
    @board.show_board
  end

  def save_as
    puts "Please input a name for your saved game:"
    puts "Press enter to quit without saving."
    gets.chomp!
  end

  def move(direction)
    if direction == :up
      @board.cursor = [((@board.cursor[0]-1) % 8), @board.cursor[1]]
    elsif direction == :down
      @board.cursor = [((@board.cursor[0]+1) % 8), @board.cursor[1]]
    elsif direction == :left
      @board.cursor = [(@board.cursor[0]), ((@board.cursor[1]-1) % 8)]
    elsif direction == :right
      @board.cursor = [(@board.cursor[0]), ((@board.cursor[1]+1) % 8)]
    end
  end
end

class Player
  attr_reader :color
  attr_accessor :name

  def initialize(color, board)
    @name = nil
    @color = color
    @board = board
  end
end

class HumanPlayer < Player
  def play_turn(start_pos, end_pos)
    raise InvalidMoveError if start_pos[1].nil? || start_pos[0].nil?
    raise InvalidMoveError unless @board.get_pieces(@color).include?(@board[start_pos])
    raise InvalidMoveError if end_pos[1].nil? || end_pos[0].nil?

    @board.move(start_pos, end_pos)
  end
end

# Rough AI player implementation
class ComputerPlayer < Player
  def generate_move
    final_scores = []
    our_pieces = @board.get_pieces(@color)
    score = @board.score(@color)

    our_pieces.shuffle.each do |piece|
      possible_moves = piece.valid_moves(@board)
      curr_distance = distance_from_enemy_king(piece.pos)

      possible_moves.each do |possible_finish|
        next_board = @board.dup
        next_board.move(piece.pos, possible_finish)
        next_score = next_board.score(@color)
        next_score += 1 if distance_from_enemy_king(possible_finish) < curr_distance

        if next_board.checkmate?(@color == :white ? :black : :white)
          return [piece.pos, possible_finish]
        end

        enemy_pieces = next_board.get_pieces(@color == :white ? :black : :white)

        enemy_pieces.each do |enemy_piece|
          enemy_moves = enemy_piece.valid_moves(next_board)
          enemy_moves.each do |enemy_move|
            enemy_board = next_board.dup
            enemy_board.move(enemy_piece.pos, enemy_move)
            enemy_move_score = enemy_board.score(@color)

            if enemy_move_score < next_score
              final_score =  score - next_score
            else
              final_score = score - enemy_move_score
            end

            final_scores << [final_score, [piece.pos, possible_finish]]
          end
        end
      end
    end

    final_scores.sort_by { |score, _| score }.first[1]
  end

  def distance_from_enemy_king(pos)
    enemy_color = @color == :white ? :black : :white
    king_pos = @board.find_king(enemy_color)

    a2 = (king_pos[0] - pos[0]) ** 2
    b2 = (king_pos[1] - pos[1]) ** 2

    (a2 + b2) ** (1.0/2)
  end

  def play_turn
    @board.move(*generate_move)
  end
end

g = Game.new
g.play