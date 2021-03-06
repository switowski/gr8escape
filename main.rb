STDOUT.sync = true # DO NOT REMOVE
require 'set'

# TODO:
# Dopracować efektywną ścianę

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
  # Remember how many enemies are there, there is no point to fight with both
  # of them in the same time
  $active_enemies = $playerCount - 1
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

def calculate_neighbors
  $neighbors = {} # Clear neighbors Hash
  (0..8).each do |x|
    (0..8).each do |y|
      # STDERR.puts "Calculating field #{x}, #{y}"
      $neighbors[[x,y]] = []
      $neighbors[[x,y]] << [x, y + 1] if can_go?([x,y], "DOWN")
      $neighbors[[x,y]] << [x, y - 1] if can_go?([x,y], "UP")
      $neighbors[[x,y]] << [x + 1, y] if can_go?([x,y], "RIGHT")
      $neighbors[[x,y]] << [x - 1, y] if can_go?([x,y], "LEFT")
    end
  end
  # STDERR.puts $neighbors
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
  if !direction.is_a? String
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
    if $walls.include?([cx, cy, 'V']) || $walls.include?([cx, cy - 1, 'V'])
      # STDERR.puts "Can't go #{direction}, there are following walls: #{$walls.to_a}"
      return false
    end
  when "UP"
    if $walls.include?([cx, cy, 'H']) || $walls.include?([cx - 1, cy, 'H'])
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
  if next_location.nil?
    return nil
  end
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
  nil
end

def get_target(current_location, player_id)
  STDERR.puts "getting target for #{player_id}"
  STDERR.puts "His current location #{current_location}"
  if escaped?(player_id)
    # STDERR.puts "He escaped"
    # Player already reached the target, ignore him
    return current_location, 99
  end
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
  path_size = 0

  while not frontier.empty?
    path_size += 1
    if path_size > 1000
      # It seems like it's impossible to reach the target
      STDERR.puts "Can't find a way"
      return nil, nil
    end
    current = frontier.pop
    if is_target?(current, player_id)
      target = current
      break
    end
    found_new = false
    previous = nil
    $neighbors[current].each do |neighbor|
      if !came_from.key?(neighbor)
        frontier << neighbor
        came_from[neighbor] = current
        found_new = true
      else
        previous = neighbor
      end
    end
    # We need to allow to go back if there is no other option
    if !found_new && !previous.nil?
      frontier << previous
    end
  end

  # Reconstruct the path
  current = target
  path = [current]
  while current != current_location
    current = came_from[current]
    path << current
  end
  # STDERR.puts "current path: #{path.slice(0..-2)}" if player_id == $myId
  # STDERR.puts "enemy 0 path: #{path.slice(0..-2)}" if player_id == 0
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

def escaped?(player_id)
  $players[player_id]['current_location'] == [-1, -1]
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
  # STDERR.puts "List of walls #{$walls.to_a}"
end

def put_wall (cx, cy, orientation)
  puts "#{cx} #{cy} #{orientation}"
end

# def get_player_id_from_location(location)
#   # Takes the field and returns the id of player on that field or nil if empty
#   $players.each_pair do |key, value|
#     if value['current_location'] == location
#       return key
#     end
#   end
#   return nil
# end

def can_build_wall?(cx, cy, orientation)
  # STDERR.puts "Trying wall: #{cx}, #{cy}, #{orientation}"
  # Returns true if you can build a wall on a location specified
  if $walls.include?([cx, cy, orientation])
    # There is already a wall here
    return false
  end
  if cx < 0 || cy < 0 || cx > 8 || cy > 8
    # Can't be less than 0 or more than 8
    # STDERR.puts "can't build 0"
    return false
  end
  if orientation == 'H'
    if $walls.include?([cx - 1, cy, orientation]) ||
      $walls.include?([cx + 1, cy, orientation])
      # The wall is overlapping with another wall
      # STDERR.puts "can't build 1"
      return false
    end
    if cx > 7 || cy == 0
      # The wall is going outside of boundaries
      # STDERR.puts "can't build 2"
      return false
    end
    if $walls.include?([cx + 1, cy - 1, 'V'])
      # It's crossing different wall
      # STDERR.puts "can't build 3"
      return false
    end
  end
  if orientation == 'V'
    if cy > 7 || cx == 0
      # The wall is going outside of boundaries
      # STDERR.puts "can't build 4"
      return false
    end
    if $walls.include?([cx, cy - 1, orientation]) ||
      $walls.include?([cx, cy + 1, orientation])
      # The wall is overlapping with another wall
      # STDERR.puts "can't build 5"
      return false
    end
    if $walls.include?([cx - 1, cy + 1, 'H'])
      # It's crossing different wall
      # STDERR.puts "can't build 6"
      return false
    end
  end
  return true
end

def get_possible_wall_positions(current_location, distance)
  # Returns all possible locations within distance from location where we can
  # put a wall.
  # Possible location means a field that player can reach, we don't check if
  # there is a wall there.
  current_neighbors = [current_location]
  distance.times do
    new_possible_neighbors = current_neighbors.dup
    current_neighbors.each do |neighbor|
      # STDERR.puts "neighbors-> #{$neighbors}"
      $neighbors[neighbor].each do |possible_neighbor|
        if !current_neighbors.include?(possible_neighbor)
          new_possible_neighbors << possible_neighbor
        end
      end
    end
    current_neighbors = new_possible_neighbors.dup
  end
  current_neighbors.uniq
end

def remove_neighbor(fake_wall, neighbors_hash)
  cx, cy, orientation = fake_wall
  list_of_removed = [] # for debugging purposes
  if orientation == "V"
    list_of_removed << neighbors_hash[[cx, cy]].delete([cx - 1, cy])
    list_of_removed << neighbors_hash[[cx - 1,cy]].delete([cx, cy])
    list_of_removed << neighbors_hash[[cx, cy + 1]].delete([cx - 1, cy + 1])
    list_of_removed << neighbors_hash[[cx - 1, cy + 1]].delete([cx, cy + 1])
  elsif orientation == "H"
    list_of_removed << neighbors_hash[[cx, cy]].delete([cx, cy - 1])
    list_of_removed << neighbors_hash[[cx, cy - 1]].delete([cx, cy])
    list_of_removed << neighbors_hash[[cx + 1, cy]].delete([cx + 1, cy - 1])
    list_of_removed << neighbors_hash[[cx + 1, cy - 1]].delete([cx + 1, cy])
  end
  # STDERR.puts "Removed: #{list_of_removed}"
end

def build_wall(enemy_id, distance = 1, slowdown = nil)
  # Get all neighbor fields for enemy and compare how much we will delay him
  # depending on where we put the wall
  # Return true if we have build a wall
  enemy_location = $players[enemy_id]['current_location']
  STDERR.puts "Enemy location: #{enemy_location}"
  neighbors = get_possible_wall_positions(enemy_location, distance)
  STDERR.puts "Possible walls locations: #{neighbors}"
  current_distance = $players[enemy_id]['distance']
  max_delay = 0
  best_wall = []
  neighbors_backup = $neighbors.dup
  neighbors.each do |neighbor|
    # STDERR.puts "neighbor: #{neighbor}"
    %w(V H).each do |o|
      possible_wall = neighbor.dup
      possible_wall << o
      STDERR.puts "possible_wall: #{possible_wall}"
      # Check if we can build there
      if !can_build_wall?(*possible_wall)
        # STDERR.puts "We can't build here: #{possible_wall}"
        next
      end
      # Deep copy through Marshalling trick
      # http://ruby.about.com/od/advancedruby/a/deepcopy.htm
      $neighbors = Marshal.load(Marshal.dump(neighbors_backup))
      # For a moment we gonna replace the real $neighbors hash with this fake
      # one to see it the distance changed
      my_distance = simulate_distance($myId)
      remove_neighbor(possible_wall, $neighbors)
      new_distance = simulate_distance(enemy_id)
      if new_distance.nil?
        # Player can't reach the exit, we can't build here
        # STDERR.puts "Won't reach exit"
        next
      end
      # Make sure other player can pass with this wall
      other_enemy = get_enemies_ids
      other_enemy.delete(enemy_id)
      if other_enemy.size == 1 && simulate_distance(other_enemy[0]).nil?
        next
      end
      # Make sure it won't slow me down more than enemy !
      my_new_distance = simulate_distance($myId)
      if my_new_distance.nil? ||
         (my_new_distance - my_distance) > (new_distance - current_distance)
        STDERR.puts "It will slow me down too much"
        next
      end
      # Restore the original content of $neighbors hash
      $neighbors = Marshal.load(Marshal.dump(neighbors_backup))
      STDERR.puts "new_distance: #{new_distance}"
      # STDERR.puts "New distance: #{new_distance}"
      if new_distance - current_distance >= max_delay
        max_delay = new_distance - current_distance
        best_wall = possible_wall
        STDERR.puts "New max delay: #{max_delay} for wall in #{best_wall}"
      end
    end
  end
  if max_delay >= slowdown
    # We have a best wall here, build it
    # STDERR.puts "Best wall for enemy at #{$players[enemy_id]['current_location']} \
    #              is: #{best_wall} and it will slow him down by #{max_delay}"
    # If the best wall is one field from the boundary, try to build it next to
    # wall so it's more efficient
    STDERR.puts "Wall before improvement: #{best_wall}"
    better_wall = improve_wall(best_wall, enemy_id)
    STDERR.puts "Wall after improvement: #{best_wall}"
    put_wall(*best_wall)
    return true
  end
  false
end

def improve_wall(wall_location, enemy_id)
  enemy_location = $players[enemy_id]['current_location']
  wx, wy, orientation = wall_location
  ex, ey = enemy_location
  etx, ety = $players[enemy_id]['target']
  better_wall = []
  # We need to check if enemy won't be blocked after improvement
  neighbors_backup = $neighbors.dup
  $neighbors = Marshal.load(Marshal.dump(neighbors_backup))
  current_distance = simulate_distance(enemy_id)
  # And if the "improved" wall is not worse than previous one (if it doesn't
  # slow down by less distance)
  if orientation == 'H'
    if ex == 1 && wx == 1 && can_build_wall?(0, wy, orientation)
      better_wall = 0, wy, orientation
    end
    if ex == 7 && wx == 6 && can_build_wall?(7, wy, orientation)
      better_wall = 7, wy, orientation
    end
  else
    if etx == 0 && ey == 1 && wy == 1 && can_build_wall?(wx, 0, orientation)
      better_wall =  wx, 0, orientation
    end
    if etx == 0  && ey == 7 && wy == 6 && can_build_wall?(wx, 7, orientation)
      better_wall =  wx, 7, orientation
    end
    if etx == 8 && ey == 1 && wy == 1 && can_build_wall?(wx, 0, orientation)
      better_wall =  wx, 0, orientation
    end
    if etx == 8  && ey == 7 && wy == 6 && can_build_wall?(wx, 7, orientation)
      better_wall =  wx, 7, orientation
    end
  end
  if better_wall != []
    remove_neighbor(better_wall, $neighbors)
    new_distance = simulate_distance(enemy_id)
    if !new_distance.nil? && new_distance >= current_distance
      $neighbors = Marshal.load(Marshal.dump(neighbors_backup))
      return better_wall
    end
  end
  # We can't improve the wall, return the previous one
  $neighbors = Marshal.load(Marshal.dump(neighbors_backup))
  wall_location
end

def move
  # Puts the direction string
  STDERR.puts "My decision here"
  puts $players[$myId]['direction']
end

def get_enemies_ids
  ids = [0, 1]
  ids << 2 if $playerCount == 3
  # Delete my ID from list of enemies
  ids.delete($myId)
  # STDERR.puts "ids before reject: #{ids}"
  ids.reject! {|id| $players[id]['current_location'] == [-1, -1]}
  # STDERR.puts "ids after reject: #{ids}"
  ids
end

def efficient_wall(enemy_id)
  # Builds a wall that will slow the enemy by at least 3 moves and returns
  # true if the wall was built or false if it wasn't
  build_wall(enemy_id, 2, 4)
end

def me_and_enemy_next_to_wall?(enemy_id)
  # It's possible that me an enemy are next to the arena edges, so the first
  # one to put the wall at the end will win
  cx, cy = $players[$myId]['current_location']
  ex, ey = $players[enemy_id]['current_location']
  if enemy_id == 2 && $myId == 0 and ex == 8 and cy == 8
    return true
  elsif enemy_id == 0 && $myId == 2 and cx == 8 and ey == 8
    return true
  elsif enemy_id == 2 && $myId == 1 and ex == 0 and cy == 8
    return true
  elsif enemy_id == 1 && $myId == 2 and cx == 0 and ey == 8
    return true
  end
  return false
end

def secure_finish
  # Single wall
  secured = secure_single_wall
  STDERR.puts "We can secure single wall" if secured.size == 3
  # Tunnel with a roof
  secured = secure_tunnel_with_roof if secured.size != 3
  STDERR.puts "We can secure double wall" if secured.size != 3
  return secured
end

def secure_single_wall
  # Legend:
  # x - my dragon
  # $ - arena wall
  # - or | - single wall

  # Try to secure single wall next to wall like that:
  #  --$
  # x  $
  # $$$$
  tx, ty = $players[$myId]['target']
  if ty == 8
    # Going down
    if $my_location == [0, 6] && can_build_wall?(1, 7, 'V')
      # Left wall
      return [1, 7, 'V']
    elsif $my_location == [8, 6] && can_build_wall?(8, 7, 'V')
      # Right wall
      return [8, 7, 'V']
    end
  elsif tx == 8
    # Going right
    if $my_location == [6, 0] && can_build_wall?(7, 1, 'H')
      # Upper wall
      return [7, 1, 'H']
    elsif $my_location == [6, 8] && can_build_wall?(7, 8, 'H')
      # Down wall
      return [7, 8, 'H']
    end
  elsif tx == 0
    # Going left
    if $my_location == [2, 0] && can_build_wall?(0, 1, 'H')
      # Upper wall
      return [0, 1, 'H']
    elsif $my_location == [2, 8] && can_build_wall?(0, 8, 'H')
      # Down wall
      return [0, 8, 'H']
    end
  end
  return []
end

def secure_tunnel_with_roof
  # Legend:
  # x - my dragon
  # $ - arena wall
  # - or | - single wall
  # * - enemy wall

  # Try to secure a tunnel of two wall and one wall above or below:
  # ----$
  #     $
  # |x* $
  # | * $
  cx, cy = $my_location
  tx, ty = $players[$myId]['target']
  # Going left
  if tx == 8
    # Step 1
    if $walls.include?([cx + 1, cy, 'V']) && can_build_wall?(cx, cy, 'V')
      return [cx, cy, 'V']
    elsif $walls.include?([cx+1, cy-1, 'V']) && can_build_wall?(cx, cy-1, 'V')
      return [cx, cy - 1, 'V']
    end
    # Step 2
    if $walls.include?([cx + 1, cy, 'V']) && $walls.include?([cx, cy, 'V'])
      if can_build_wall?(cx, cy - 1, 'H')
        # Roof above tunnel
        return [cx, cy - 1, 'H']
      elsif can_build_wall?(cx, cy + 3, 'H')
        # Roof below tunnel
        return [cx, cy + 3, 'H']
      end
    elsif $walls.include?([cx+1, cy-1, 'V']) && $walls.include?([cx, cy-1, 'V'])
      if can_build_wall?(cx, cy - 2, 'H')
        return [cx, cy - 2, 'H']
      elsif can_build_wall?(cx, cy + 2, 'H')
        return [cx, cy + 2, 'H']
      end
    end
  elsif tx == 0
    # Going right
    # Step 1
    if $walls.include?([cx, cy, 'V']) && can_build_wall?(cx + 1, cy, 'V')
      return [cx + 1, cy, 'V']
    elsif $walls.include?([cx, cy-1, 'V']) && can_build_wall?(cx+1, cy-1, 'V')
      return [cx + 1, cy - 1, 'V']
    end
    # Step 2
    if $walls.include?([cx, cy, 'V']) && $walls.include?([cx + 1, cy, 'V'])
      if can_build_wall?(cx - 1, cy - 1, 'H')
        # Roof above tunnel
        return [cx - 1, cy - 1, 'H']
      elsif can_build_wall?(cx - 1, cy + 3, 'H')
        # Roof below tunnel
        return [cx - 1, cy + 3, 'H']
      end
    elsif $walls.include?([cx, cy-1, 'V']) && $walls.include?([cx+1, cy-1, 'V'])
      if can_build_wall?(cx - 1, cy - 2, 'H')
        return [cx - 1, cy - 2, 'H']
      elsif can_build_wall?(cx - 1, cy + 2, 'H')
        return [cx - 1, cy + 2, 'H']
      end
    end
  elsif ty == 8
    # Going down
    # Step 1
    if $walls.include?([cx, cy + 1, 'H']) && can_build_wall?(cx, cy, 'H')
      return [cx, cy, 'H']
    elsif $walls.include?([cx-1, cy+1, 'H']) && can_build_wall?(cx-1, cy, 'H')
      return [cx-1, cy, 'H']
    end
    # Step 2
    if $walls.include?([cx, cy + 1, 'H']) && $walls.include?([cx, cy, 'H'])
      if can_build_wall?(cx - 1, cy, 'V')
        # Roof left from tunnel
        return [cx - 1, cy, 'V']
      elsif can_build_wall?(cx + 3, cy, 'V')
        # Roof right from tunnel
        return [cx + 3, cy, 'V']
      end
    elsif $walls.include?([cx-1, cy+1, 'H']) && $walls.include?([cx-1, cy, 'H'])
      if can_build_wall?(cx - 2, cy, 'V')
        return [cx - 2, cy, 'V']
      elsif can_build_wall?(cx + 2, cy, 'V')
        return [cx + 2, cy, 'V']
      end
    end
  end
  return []
end

def enemy_close_to_win?(enemy_id)
  # Returns true if the enemy is close to winning:
  # Either he is one space from finish
  # Or he is 2 spaces and he is in the corner, so we won't be able to put wall
  # later there, like that:
  # $ |
  # $ |x
  # $
  # $$$$$
  if $players[enemy_id]['distance'] == 1
    return true
  end
  # Corner cases
  ex, ey = $players[enemy_id]['current_location']
  tx, ty = $players[enemy_id]['target']
  if tx == 0 && ex == 1
    # Going left
    if $walls.include?([1, 6, 'V']) && ey == 7
      return true
    elsif $walls.include?([1, 1, 'V']) && ey == 1
      return true
    end
  elsif tx == 8 && ex == 7
    # Going right
    if $walls.include?([8, 6, 'V']) && ey == 7
      return true
    elsif $walls.include?([8, 1, 'V']) && ey == 1
      return true
    end
  elsif ty == 8 && ey == 7
    # Going down
    if $walls.include?([1, 8, 'H']) && ex == 1
      return true
    elsif $walls.include?([6, 8, 'H']) && ex == 7
      return true
    end
  end
  return false
end

def print_decision
  # Write an action using puts
  # To debug: STDERR.puts 'Debug messages...'
  # action: LEFT, RIGHT, UP, DOWN or 'putX putY putOrientation' for wall

  STDERR.puts "Printing decision"
  # If we don't have any wall left, just move
  if $players[$myId]['walls'] == 0
    move
    return
  end
  enemies = get_enemies_ids

  if enemies.size == 2
    # If I'm last and both of them are one step from exit, we need to stop one
    STDERR.puts "MYID: #{$myId}"
    STDERR.puts "dist1: #{$players[enemies[0]]['distance']}"
    STDERR.puts "dist2: #{$players[enemies[0]]['distance']}"
    if $myId == 2 && $players[enemies[0]]['distance'] == 1 &&
       $players[enemies[1]]['distance'] == 1
      built = build_wall(enemies[0], 1, 1)
      # It's possible that that wall would slow me down, maybe we can stop the
      # other enemy ?
      built = build_wall(enemies[1], 1, 1) if !built
      return if built
    else
      move
      return
    end
  end
  enemy_id = enemies[0]
  # Build wall if the enemy is 1 step from the finish
  # STDERR.puts "Enemy: #{enemy_id} distance: #{$players[enemy_id]['distance']}"
  if enemy_close_to_win?(enemy_id)
    STDERR.puts "Will try to build a wall to stop enemy from winning"
    built = build_wall(enemy_id, 2, 1)
    return if built
  end

  if $players[$myId]['distance'] == 2
    # If we have 2 moves remaining, secure my path various methods
    STDERR.puts "Trying to secure my victory"
    possible_wall = secure_finish
    if possible_wall.size == 3
      # Make sure we are not blocking anyone
      neighbors_backup = $neighbors.dup
      $neighbors = Marshal.load(Marshal.dump(neighbors_backup))
      new_enemy_distance = simulate_distance(enemy_id)
      $neighbors = Marshal.load(Marshal.dump(neighbors_backup))
      if !new_enemy_distance.nil?
        put_wall(*possible_wall)
        return
      end
    end
  end

  if enemies.size == 2
    # If there are 2 enemies, we can't fight them both. Only build a wall
    # if it will slow any of them by more than 2 moves
    wall_1 = efficient_wall(enemies[0])
    return if wall_1
    wall = efficient_wall(enemies[1])
    return if wall
  else
    # See if we can build a wall that will delay the enemy by 3 or more moves
    wall = efficient_wall(enemies[0])
    return if wall
  end

  # end
  # If we got that far, move
  move
end

def main
  # game loop
  loop do
    save_players
    save_walls
    calculate_neighbors
    calculate_next_move
    print_decision
  end
end

init
main
