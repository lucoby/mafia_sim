

class Player
	def initialize(faction)
		@faction = faction
		@alive = true
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
		@has_action = false
	end
end

class Doctor < Player
	def initialize(faction)
		super
		@faction_type = :Town
		@investigate = :Town
		@has_action = true
	end

	def action (village)
		target = Random.rand(village.count_alive_village) - 1
		village.factions.each do |f|
			f.players.each do |p|
				if p.alive
					if target <= 0 && p != self
						return Action.new(:Protect, self, p)
					else
						target -= 1
					end
				end
			end
		end
	end
end

class Cop < Player
	def initialize(faction)
		super
		@faction_type = :Town
		@investigate = :Town
		@has_action = true
	end

	def action (village)
		target = Random.rand(village.count_alive_village) - 1
		village.factions.each do |f|
			f.players.each do |p|
				if p.alive
					if target <= 0 && p != self
						return Action.new(:Investigate, self, p)
					else
						target -= 1
					end
				end
			end
		end
	end
end

class Goon < Player
	def initialize(faction)
		super
		@faction_type = :Mafia
		@investigate = :Mafia
		@has_action = false
	end

	def action (village)
		target = Random.rand(village.count_alive_village - faction.count_alive_faction)
		village.factions.each do |f|
			if f.faction != @faction.faction
				f.players.each do |p|
					if p.alive
						if target == 0
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
		@executed = false
	end

	attr_accessor :type
	attr_accessor :actor
	attr_accessor :target
	attr_accessor :executed
end