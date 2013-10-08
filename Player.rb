

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