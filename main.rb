STDOUT.sync = true # DO NOT REMOVE
require 'set'

# Plan:
# if there is a chance to slow down enemy by 3 or more moves with a wall, build a wall
# if there is enemy closer to the end than I am and he has 3 or less moves to win, build a wall
# if I'm closer to the end, move
# if I don't have walls, move

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
  # In case direction is not a string but a coordinate
  if ! direction.is_a? String
    direction = coordinates_to_direction(current_location, direction)
  end
  # STDERR.puts "Checking if can go #{direction} from #{current_location}"
  # STDERR.puts "List of walls #{$walls.to_a}"

  # If the location is outside of the board, return false
  return false if not in_boundaries?(current_location, direction)

  case direction
  when "RIGHT"
    if $walls.include?([cx + 1, cy, 'V']) || $walls.include?([cx + 1, cy - 1, 'V'])
      STDERR.puts "Can't go #{direction}, there are following walls: #{$walls.to_a}"
      return false
    end
  when "LEFT"
    if $walls.include?([cx - 1, cy, 'V']) || $walls.include?([cx - 1, cy - 1, 'V'])
      STDERR.puts "Can't go #{direction}, there are following walls: #{$walls.to_a}"
      return false
    end
  when "UP"
    if $walls.include?([cx, cy - 1, 'H']) || $walls.include?([cx - 1, cy - 1, 'H'])
      STDERR.puts "Can't go #{direction}, there are following walls: #{$walls.to_a}"
      return false
    end
  when "DOWN"
    if $walls.include?([cx, cy + 1, 'H']) || $walls.include?([cx - 1, cy + 1, 'H'])
      STDERR.puts "Can't go #{direction}, there are following walls: #{$walls.to_a}"
      return false
    end
  end
  return true
end

def coordinates_to_direction(current_location, next_location)
  cx, cy = current_location
  nx, ny = next_location
  if nx == cx + 1 && ny == cy
    return "RIGHT"
  elsif nx == cx - 1 && ny == cy
    return "LEFT"
  elsif ny == cy + 1 and nx == cx
    return "DOWN"
  elsif ny == cy - 1 and nx == cx
    return "UP"
  end
  nil
end

def direction_to_coordinates(current_location, direction)
  cx, cy = current_location
  case direction
  when "RIGHT"
    return cx + 1, cy
  when "LEFT"
    return cx - 1, cy
  when "UP"
    return cy + 1, cx
  when "DOWN"
    return cy - 1, cx
  end
  STDERR.puts "Error in direction_to_coordinates. Incorrect coordinates: \
               current: #{current_location}, direction: #{direction}"
  nil
end

def get_target(current_location)
  next_move, path_size = find_my_next_location(current_location)
  direction = coordinates_to_direction(current_location, next_move)
  return direction, path_size
end

def find_my_next_location(current_location)
  find_next_location(current_location, $myId)
end

def find_next_location(current_location, player_id)
  # Breadth First Search algorithm for path finding
  # TODO: if it's to slow, replace it with A*
  frontier = Queue.new
  frontier << current_location
  came_from = {}
  came_from[current_location] = nil

  while not frontier.empty?
    current = frontier.pop
    if is_target?(current, player_id)
      target = current
      break
    end
    neighbors(current).each do |neighbor|
      if not came_from.has_key?(neighbor)
        frontier << neighbor
        came_from[neighbor] = current
      end
    end
  end

  # Reconstruct the path
  current = target
  path = [current]
  while current != current_location
    current = came_from[current]
    path << current
  end
  STDERR.puts "current path: #{path}"
  path_size = path.size - 1
  next_move = path.slice(-2) # -2 since -1 is the current_location
  return next_move, path_size
end

def is_target?(current_location, player_id)
  cx, cy = current_location
  tx, ty = $players[player_id]['target']
  if (tx && tx == cx) || (ty && ty == cy)
    return true
  end
  false
end

def neighbors(current_location)
  cx, cy = current_location
  possible_neighbors = [ [cx + 1, cy], [cx - 1, cy],
                         [cx, cy + 1], [cx, cy - 1] ]
  possible_neighbors.select { |target| can_go?(current_location, target) }
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

def put_wall (location, orientation)
  puts location[0], location[1], orientation.capitalize
end

def print_decision
  # Write an action using puts
  # To debug: STDERR.puts 'Debug messages...'
  # action: LEFT, RIGHT, UP, DOWN or 'putX putY putOrientation' for wall
  # Try to go right and if it's not possible - down and right
  my_direction, my_distance = get_target($players[$myId]['current_location'])
  # See which enemy is closer to the end
  STDERR.puts $players
  if $myId != 0
    _, player0_distance = get_target($players[0]['current_location'])
  end
  if $myId != 2
    _, player1_distance = get_target($players[1]['current_location'])
  end
  if $playerCount > 2 and $myId != 2
    _, player2_distance = get_target($players[2]['current_location'])
  end
  if player0_distance and player1_distance
    if player0_distance > player1_distance
      worst_enemy = 1
      enemy_distance = player1_distance
    else
      worst_enemy = 0
      enemy_distance = player0_distance
    end
  elsif player0_distance and player2_distance
    if player0_distance > player2_distance
      worst_enemy = 2
      enemy_distance = player2_distance
    else
      worst_enemy = 0
      enemy_distance = player0_distance
    end
  elsif player1_distance and player2_distance
    if player1_distance > player2_distance
      worst_enemy = 2
      enemy_distance = player2_distance
    else
      worst_enemy = 1
      enemy_distance = player1_distance
    end
  end

  STDERR.puts "enemy distance #{enemy_distance}, my distance: #{my_distance}"
  if enemy_distance < my_distance && $players[$myId]['walls'] > 0
    # put a wall on enemy position
    put_wall($players[worst_enemy]['current_location'], 'H')
  else
    puts direction
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
