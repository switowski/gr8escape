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
  $round_number = 0 # Stores the round number

  $players[0] = {'target' => [8, nil]}
  $players[1] = {'target' => [0, nil]}
  $players[2] = {'target' => [nil, 8]} if $playerCount > 2
end

def save_players
  $round_number += 1
  $playerCount.times do |i|
    # x: x-coordinate of the player
    # y: y-coordinate of the player
    # wallsLeft: number of walls available for the player
    x, y, wallsLeft = gets.split(' ').collect(&:to_i)
    $players[i]['current_location'] = [x, y]
    $players[i]['walls'] = wallsLeft
  end
end

def calculate_next_move
  # Store my_location as global variable for easier access
  $my_location = $players[$myId]['current_location']
  # Calculate next move and distance for all players
  calculate_all_target_distance
end

def can_go?(current_location, direction)
  # Direction can be a string or coordinate
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
      # STDERR.puts "Can't go #{direction}, there are following walls: #{$walls.to_a}"
      return false
    end
  when "LEFT"
    if $walls.include?([cx - 1, cy, 'V']) || $walls.include?([cx - 1, cy - 1, 'V'])
      # STDERR.puts "Can't go #{direction}, there are following walls: #{$walls.to_a}"
      return false
    end
  when "UP"
    if $walls.include?([cx, cy - 1, 'H']) || $walls.include?([cx - 1, cy - 1, 'H'])
      # STDERR.puts "Can't go #{direction}, there are following walls: #{$walls.to_a}"
      return false
    end
  when "DOWN"
    if $walls.include?([cx, cy + 1, 'H']) || $walls.include?([cx - 1, cy + 1, 'H'])
      # STDERR.puts "Can't go #{direction}, there are following walls: #{$walls.to_a}"
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

def get_target(current_location, player_id)
  next_move, path_size = find_next_location(current_location, player_id)
  direction = coordinates_to_direction(current_location, next_move)
  return direction, path_size
end

def calculate_all_target_distance
  # Calculates the distance and possible direction for each player
  all_ids = [0, 1]
  all_ids << 2 if $playerCount == 3
  all_ids.each do |id|
    direction, distance = get_target($players[id]['current_location'], id)
    $players[id]['direction'] = direction
    $players[id]['distance'] = distance
  end
end

def simulate_distance(player_id)
  # Returns the distance to target for a player
  current_location = $players[player_id]['current_location']
  _, dist = find_next_location(current_location, player_id)
  return dist
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
    get_neighbors(current).each do |neighbor|
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
  STDERR.puts "current path: #{path}" if player_id == $myId
  path_size = path.size - 1
  next_move = path.slice(-2) # -2 since -1 is the current_location
  return next_move, path_size
end

def is_target?(current_location, player_id)
  # Returns true, if the current field is a target for a given player
  cx, cy = current_location
  tx, ty = $players[player_id]['target']
  if (tx && tx == cx) || (ty && ty == cy)
    return true
  end
  false
end

def get_neighbors(current_location)
  # Returns an array with neighbor fields coordinates
  cx, cy = current_location
  possible_neighbors = [ [cx + 1, cy], [cx - 1, cy],
                         [cx, cy + 1], [cx, cy - 1] ]
  possible_neighbors.select { |target| can_go?(current_location, target) }
end

def in_boundaries?(current_location, direction)
  # Returns true if the current_location is within boundaries of the board
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
  $walls = Set.new # empty the $walls array
  wallCount.times do
    # wallX: x-coordinate of the wall
    # wallY: y-coordinate of the wall
    # wallOrientation: wall orientation ('H' or 'V')
    wallX, wallY, wallOrientation = gets.split(' ')
    wallX = wallX.to_i
    wallY = wallY.to_i
    $walls << [wallX, wallY, wallOrientation]
  end
  STDERR.puts "List of walls #{$walls.to_a}"
end

def put_wall (cx, cy, orientation)
  puts "#{cx} #{cy} #{orientation}"
end

def get_player_id_from_location(location)
  # Takes the field and returns the id of player on that field or nil if empty
  $players.each_pair do |key, value|
    if value['current_location'] == location
      return key
    end
  end
  return nil
end

def can_build_wall?(cx, cy, orientation)
  # Returns true if you can build a wall on a location specified
  if $walls.include?([cx, cy, orientation])
    # There is already a wall here
    return false
  end
  if cx < 0 || cy < 0
    # Can't be less than 0
    return false
  end
  if orientation == 'H'
    if $walls.include?([cx - 1, cy, orientation]) ||
      $walls.include?([cx + 1, cy, orientation])
      # The wall is overlapping with another wall
      return false
    end
    if cx > 8 || cx == 0
      # The wall is going outside of boundaries
      return false
    end
    if $walls.include?([cx + 1, cy - 1, 'V'])
      # It's crossing different wall
      return false
    end
  end
  if orientation == 'V'
    if cy > 8 || cy == 0
      # The wall is going outside of boundaries
      return false
    end
    if $walls.include?([cx, cy - 1, orientation]) ||
      $walls.include?([cx, cy + 1, orientation])
      # The wall is overlapping with another wall
      return false
    end
    if $walls.include?([cx - 1, cy + 1, 'H'])
      # It's crossing different wall
      return false
    end
  end
  return true
end

def get_neighbors_for_wall(id, distance)
  cx, cy = $players[id]['current_location']
  possible_neighbors = [[cx-2, cy], [cx-1, cy], [cx+1, cy], [cx+2, cy],
                        [cx, cy-2], [cx, cy-1], [cx, cy+1], [cx, cy+2]]
  neighbors = possible_neighbors.select do |neighbor|
    can_go?([cx, cy], neighbor)
  end
  # We can always build a wall on the current field of enemy
  neighbors << [cx, cy]
  return neighbors
end

def build_wall(enemy_id)
  # Get all neighbor fields for enemy and compare how much we will delay him
  # depending on where we put the wall
  # Return true if we have build a wall
  neighbors = get_neighbors_for_wall(enemy_id, 2)
  STDERR.puts "Possible neighbors: #{neighbors}"
  current_distance = $players[enemy_id]['distance']
  max_delay = 0
  best_wall = []
  walls_backup = $walls.dup
  neighbors.each do |neighbor|
    ['V', 'H'].each do |o|
      $walls = walls_backup.dup  # dup is very important here
      possible_wall = neighbor.dup
      possible_wall << o
      STDERR.puts "possible_wall: #{possible_wall}"
      # Check if we can build there
      if ! can_build_wall?(*possible_wall)
        STDERR.puts "We can't build here: #{possible_wall}"
        next
      end
      $walls << possible_wall
      # For a moment we gonna replace the real walls with $walls + 1 wall more
      new_distance = simulate_distance(enemy_id)
      STDERR.puts "New distance: #{new_distance}"
      $walls = walls_backup.dup
      if new_distance - current_distance > max_delay
        max_delay = new_distance - current_distance
        STDERR.puts "New max delay: #{max_delay}"
        best_wall = possible_wall
      end
    end
  end
  if max_delay > 0
    # We have a best wall here, build it
    STDERR.puts "Best wall for enemy at #{$players[enemy_id]['current_location']} \
                 is: #{best_wall} and it will slow him down by #{max_delay}"
    put_wall(*best_wall)
    return true
  end
  return false
end

def move
  # Puts the direction string
  puts $players[$myId]['direction']
end

def print_decision
  # Write an action using puts
  # To debug: STDERR.puts 'Debug messages...'
  # action: LEFT, RIGHT, UP, DOWN or 'putX putY putOrientation' for wall

  # Get the better enemy (the one closer to the end)
  ids = [0,1]
  ids << 2 if $playerCount == 3
  if ids.length == 1
    enemy_id = ids[0]
  else
    if $players[ids[0]]['distance'] < $players[ids[1]]['distance']
      enemy_id = ids[0]
    else
      enemy_id = ids[1]
    end
  end
  # For the first 3 rounds don't bother with building walls
  if $round_number < 4
    move
    return
  end
  # If the enemy distance is closer to the target, put a wall in his path
  if $players[enemy_id]['distance'] < $players[$myId]['distance']
    STDERR.puts "Will try to build a wall"
    built = build_wall(enemy_id)
    if not built
      move
    end
  # Otherwise, move
  else
    move
  end
end

def main
  # game loop
  loop do
    save_players
    save_walls
    calculate_next_move
    print_decision
  end
end

init
main
