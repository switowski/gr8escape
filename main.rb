STDOUT.sync = true # DO NOT REMOVE
# Auto-generated code below aims at helping you parse
# the standard input according to the problem statement.

$players = {} # Hash with players informations
$walls = [] # Array of walls information

def init
  # w: width of the board
  # h: height of the board
  # playerCount: number of players (2 or 3)
  # myId: id of my player (0 = 1st player, 1 = 2nd player, ...)
  $w, $h, $playerCount, $myId = gets.split(' ').collect(&:to_i)

end

def distance_to_win(current_location, target_wall)
  10
end

def save_players
  $playerCount.times do |i|
    # x: x-coordinate of the player
    # y: y-coordinate of the player
    # wallsLeft: number of walls available for the player
    $x, $y, $wallsLeft = gets.split(' ').collect(&:to_i)
    $players[i][x] = $x
    $players[i][y] = $y
    $players[i][w] = $wallsLeft
  end
end

def save_walls
  $wallCount = gets.to_i # number of walls on the board
  $wallCount.times do
    # wallX: x-coordinate of the wall
    # wallY: y-coordinate of the wall
    # wallOrientation: wall orientation ('H' or 'V')
    $wallX, $wallY, $wallOrientation = gets.split(' ')
    $wallX = $wallX.to_i
    $wallY = $wallY.to_i
    $walls << [wallX, wallY, wallOrientation]
  end
end

def print_decision
  # Write an action using puts
  # To debug: STDERR.puts 'Debug messages...'
  # action: LEFT, RIGHT, UP, DOWN or 'putX putY putOrientation' for wall
  puts 'RIGHT'
end

def main
  # game loop
  loop do
    save_walls
    save_walls
    print_decision
  end
end

init
main
