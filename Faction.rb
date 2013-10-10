require_relative 'Player'

class Faction
	def initialize(village, faction, role_hash)
		@village = village
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
			p = Townie.new(self)
			@players.concat([p])
		when :Goon
			p = Goon.new(self)
			@players.concat([p])
		when :Doctor
			p = Doctor.new(self)
			@players.concat([p])
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

	def win?
	end

	attr_accessor :faction
	attr_accessor :players
	attr_accessor :type
end

class Town < Faction
	def initialize(village, faction, role_hash)
		super
		@type = :Town
	end

	def win?
		@village.factions.each do |f|
			if f.type != :Town && f.count_alive_faction != 0
				return false
			end
		end
		return true
	end
end

class Mafia < Faction
	def initialize(village, faction, role_hash)
		super
		@type = :Mafia
	end

	def win?
		@village.factions.each do |f|
			if !(f.type != :Town || f.faction != @faction) && f.count_alive_faction != 0
				return false
			end
		end
		if count_alive_faction >= @village.count_alive_village.to_f / 2
			return true
		end
	end

	def set_killer
		set_action = false
		@players.each_with_index do |p,i|
			if p.alive && !set_action
				if $DEBUG
					puts "Mafia #{i} is the killer"
				end
				p.has_action = true
				set_action = true
			else
				p.has_action = false
			end
		end
	end
end

