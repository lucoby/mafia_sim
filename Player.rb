

class Player
	def initialize(faction)
		@faction = faction
		@alive = true
		@blocked = 0
		@protected = 0
		@has_kill = false
	end

	def action (village)
	end

	def undo_action(village)
	end

	attr_accessor :has_kill
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
		village.each_player do |p|
			if p.alive && target <= 0 && p != self
				return [Action.new(:Protect, self, p)]
			elsif p.alive
				target -= 1
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
		@investigated_players = Array.new()
	end

	def action (village)
		target = Random.rand(village.count_alive_village) - 1 - @investigated_players.length
		village.each_player do |p|
			if p.alive
				investigated = false
				@investigated_players.each do |i|
					if i == p
						investigated = true
					end
				end
				if target <= 0 && p != self && !investigated
					@investigated_players.concat([p])
					return [Action.new(:Investigate, self, p)]
				else
					target -= 1
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
		village.each_player do |p|
			if p.alive && target == 0 && @faction != p.faction
				return [Action.new(:Kill, self, p)]
			elsif p.alive
				target -= 1
			end
		end
	end
end

class RoleBlocker < Player
	def initialize(faction)
		super
		@faction_type = :Mafia
		@investigate = :Mafia
		@has_action = true
	end

	def action (village)
		block_action = nil
		kill_action = nil
		if @has_kill
			target = Random.rand(village.count_alive_village - faction.count_alive_faction)
			village.each_player do |p|
				if p.alive && target <= 0 && @faction != p.faction && kill_action == nil
					kill_action = Action.new(:Kill, self, p)
				elsif p.alive && @faction != p.faction
					target -= 1
				end
			end
		end
		target = Random.rand(village.count_alive_village - faction.count_alive_faction)
		if @has_kill
			target = Random.rand(village.count_alive_village - faction.count_alive_faction - 1)
		end
		village.each_player do |p|
			if p.alive && target <= 0 && @faction != p.faction && block_action == nil
				block_action = Action.new(:Block, self, p)
				target -= 1
			else
				target -= 1
			end
		end
		puts "Roleblocker has kill? #{@has_kill}"
		if @has_kill
			return [block_action,kill_action]
		end
		return [block_action]
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