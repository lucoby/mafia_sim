require_relative 'Player'

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
