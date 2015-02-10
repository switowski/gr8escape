STDOUT.sync = true # DO NOT REMOVE
require 'set'
# Auto-generated code below aims at helping you parse
# the standard input according to the problem statement.


def init
  # w: width of the board
  # h: height of the board
  # playerCount: number of players (2 or 3)
  # myId: id of my player (0 = 1st player, 1 = 2nd player, ...)
  $w, $h, $playerCount, $myId = gets.split(' ').collect(&:to_i)

  $players = {} # Hash with players informations
  $walls = Set.new # Array of walls information

  $players[0] = {'target' => [8, nil]}
  $players[1] = {'target' => [0, nil]}
  $players[2] = {'target' => [nil, 8]} if $playerCount > 2
end

def distance_to_win(current_location, target_wall)
  9
end

def save_players
  $playerCount.times do |i|
    # x: x-coordinate of the player
    # y: y-coordinate of the player
    # wallsLeft: number of walls available for the player
    x, y, wallsLeft = gets.split(' ').collect(&:to_i)
    $players[i]['current_location'] = [x, y]
    $players[i]['walls'] = wallsLeft
  end
end

def can_go?(current_location, direction)
  cx, cy = current_location
  STDERR.puts "Checking if can go #{direction} from #{current_location}"
  STDERR.puts "List of walls #{$walls.to_a}"

  # If the location is outside of the board, return false
  return false if not in_boundaries?(current_location, direction)

  case direction
  when "RIGHT"
    if $walls.include?([cx + 1, cy, 'V']) || $walls.include?([cx + 1, cy - 1, 'V'])
      return false
    end
  when "LEFT"
    if $walls.include?([cx - 1, cy, 'V']) || $walls.include?([cx - 1, cy - 1, 'V'])
      return false
    end
  when "UP"
    if $walls.include?([cx, cy - 1, 'H']) || $walls.include?([cx - 1, cy - 1, 'H'])
      return false
    end
  when "DOWN"
    if $walls.include?([cx, cy + 1, 'H']) || $walls.include?([cx - 1, cy + 1, 'H'])
      return false
    end
  end
  return true
end

def in_boundaries?(current_location, direction)
  case direction
  when "UP"
    return false if current_location[1] == 0
  when "DOWN"
    return false if current_location[1] == 8
  when "LEFT"
    return false if current_location[0] == 0
  when "RIGHT"
    return false if current_location[0] == 8
  end
  true
end

def save_walls
  wallCount = gets.to_i # number of walls on the board
  wallCount.times do
    # wallX: x-coordinate of the wall
    # wallY: y-coordinate of the wall
    # wallOrientation: wall orientation ('H' or 'V')
    wallX, wallY, wallOrientation = gets.split(' ')
    wallX = wallX.to_i
    wallY = wallY.to_i
    $walls << [wallX, wallY, wallOrientation]
  end
end

def print_decision
  # Write an action using puts
  # To debug: STDERR.puts 'Debug messages...'
  # action: LEFT, RIGHT, UP, DOWN or 'putX putY putOrientation' for wall
  # Try to go right and if it's not possible - down and right
  if can_go?($players[$myId]['current_location'], 'RIGHT')
    puts 'RIGHT'
  elsif can_go?($players[$myId]['current_location'], 'UP')
    puts 'UP'
  elsif can_go?($players[$myId]['current_location'], 'DOWN')
    puts 'DOWN'
  end
end

def main
  # game loop
  loop do
    save_players
    save_walls
    print_decision
  end
end

init
main
