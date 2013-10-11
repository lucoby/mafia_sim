require_relative 'Village'

#Mafia monte carlo sim
$TRIALS = 10000
$START_DAY = true
$TOWN_SETUP = {:Townie => 9, :Doctor => 1, :Cop => 1}
#$TOWN_SETUP = {:Townie => 13}
$MAFIA_SETUP = {:Goon => 2}
$VILLAGE_SETUP = {:Town => $TOWN_SETUP, :Mafia => $MAFIA_SETUP}
$DEBUG = false
$SUPER_DEBUG = false
if $DEBUG
	$TRIALS = 1
end

town_wins = 0
mafia_wins = 0

(1..$TRIALS).each do
	#initialize town
	if $DEBUG
		puts "\n---\nNEW TRIAL\n---\n"
	end
	village = Village.new($VILLAGE_SETUP)
	day = $START_DAY
	
	#simulate game
	game_over = false
	while !game_over do
		case day
		when true
			if $DEBUG
				puts "SOD Town = #{village.factions[0].count_alive_faction} Mafia = #{village.factions[1].count_alive_faction}"
			end
			village.lynch
			day = false
		when false
			if $DEBUG
				puts "SON Town = #{village.factions[0].count_alive_faction} Mafia = #{village.factions[1].count_alive_faction}"
			end
			village.night_actions
			day = true
		end

		if $SUPER_DEBUG
			village.print_details
		end

		village.factions.each do |f|
			if f.faction == :Town && f.win?
				game_over = true
				town_wins += 1
				if $DEBUG
					puts "Town wins"
				end
			end
			if f.faction == :Mafia && f.win?
				game_over = true
				mafia_wins += 1
				if $DEBUG
					puts "Mafia wins"
				end
			end
		end
	end
end
puts "Town wins: #{town_wins.to_f / $TRIALS.to_f * 100} \nMafia wins: #{mafia_wins.to_f / $TRIALS.to_f * 100}\n"