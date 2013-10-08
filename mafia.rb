#Mafia monte carlo sim
$TRIALS = 10000
$START_DAY = true
$TOWN_SETUP = {:Townie =>11}
$MAFIA_SETUP = {:Goon => 2}
$VILLAGE_SETUP = {:Town => $TOWN_SETUP, :Mafia => $MAFIA_SETUP}
$DEBUG = false


class Village
	def initialize(faction_hash)
		@factions = Array.new
		faction_hash.each do |faction, role_hash|
			case faction
			when :Town
				@factions.concat([Town.new(faction, role_hash)])
			when :Mafia
				@factions.concat([Mafia.new(faction, role_hash)])
			end
		end
		@dead = Array.new()
	end

	def count_alive_village
		alive = 0
		@factions.each do |f|
			alive += f.count_alive_faction
		end
		alive
	end

	def wins?(faction)
		case faction.type
		when :Town
			@factions.each do |f|
				if f.type != :Town && f.count_alive_faction != 0
					return false
				end
			end
			return true
		when :Mafia
			@factions.each do |f|
				if !(f.type != :Town || f.faction != faction.faction) && f.count_alive_faction != 0
					return false
				end
			end
			if faction.count_alive_faction >= count_alive_village.to_f / 2
				return true
			end
		end
		return false
	end

	def lynch
		target = Random.rand(count_alive_village)
		@factions.each do |f|
			f.players.each do |p|
				if p.alive
					if target == 0
						p.alive = false
						if $DEBUG
							puts "Lynched: #{p.faction_type}"
						end
						return
					else
						target -= 1
					end
				end
			end
		end
	end

	def night_actions
		#Set mafia kill
		@factions.each do |f|
			if f.type == :Mafia
				actor = Random.rand(f.count_alive_faction)
				if $DEBUG
					puts "mafia kill actor: #{actor}"
				end
				f.players.each do |p|
					if p.alive
						if actor == 0
							p.has_action = true
							break
						else
							actor -= 1
						end
					end
				end
			end
		end

		#Gather actions
		@actions = Hash.new()
		@factions.each do |f|
			f.players.each do |p|
				if (p.alive && p.has_action)
					action = p.action(self)
					if $DEBUG
						puts "Gathered action type: #{action.type}, actor: #{action.actor.faction_type}, target: #{action.target.faction_type}"
					end
					@actions.merge({action.type  => action}) {|key, old_val, new_val| [old_val, new_val]}
					if action.type == :Kill && p.faction_type == :Mafia
						p.has_action = false
					end
				end
			end
		end

		#Evaluate actions
		if @actions.has_key?(:Kill)
			@actions[:Kill].each do |a|
				if (a.actor.alive && !a.actor.blocked)
					a.target.alive = false
				end
			end
		end
	end

	attr_accessor :factions
	attr_accessor :dead
end


class Faction
	def initialize(faction, role_hash)
		@faction = faction
		case @faction
		when :Mafia
			@type = :Mafia
		when :Town
			@type = :Town
		end
		@players = Array.new
		role_hash.each do |role, n|
			n.times do
				make_player(role)
			end
		end
	end

	def make_player(role)
		case role
		when :Townie
			@players.concat([Townie.new(self)])
		when :Goon
			@players.concat([Goon.new(self)])
		else
			puts "Invalid role: #{role}"
		end
	end
	
	def count_alive_faction
		alive = 0
		@players.each do |p|
			if p.alive
				alive += 1
			end
		end
		#puts "counting faction: #{@faction} count = #{alive}"
		alive
	end

	attr_accessor :faction
	attr_accessor :players
	attr_accessor :type
end

class Town < Faction
	def initialize(faction, role_hash)
		super
		@type = :Town
	end
end

class Mafia < Faction
	def initialize(faction, role_hash)
		super
		@type = :Mafia
	end

end

class Player
	def initialize(faction)
		@faction = faction
		@alive = true
		@has_action = false
		@blocked = false
		@protected = false
	end

	def action (village)
	end

	attr_accessor :faction
	attr_accessor :alive
	attr_accessor :investigate
	attr_accessor :faction_type
	attr_accessor :has_action
	attr_accessor :blocked
	attr_accessor :protected
end

class Townie < Player
	def initialize(faction)
		super
		@faction_type = :Town
		@investigate = :Town
	end
end

class Goon < Player
	def initialize(faction)
		super
		@faction_type = :Mafia
		@investigate = :Mafia
	end

	def action (village)
		target = Random.rand(village.count_alive_village - faction.count_alive_faction)
		village.factions.each do |f|
			if f.faction != @faction.faction
				f.players.each do |p|
					if p.alive
						if target == 0
							p.alive = false
							return Action.new(:Kill, self, p)
						else
							target -= 1
						end
					end
				end
			end
		end
	end
end

class Action
	def initialize(type, actor, target)
		@type = type
		@actor = actor
		@target = target
	end

	attr_accessor :type
	attr_accessor :actor
	attr_accessor :target
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

		village.factions.each do |f|
			if f.faction == :Town && village.wins?(f)
				game_over = true
				town_wins += 1
				if $DEBUG
					puts "Town wins"
				end
			end
			if f.faction == :Mafia && village.wins?(f)
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