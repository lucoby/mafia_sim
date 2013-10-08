#require_relative 'Mafia_Sim'
require_relative 'Faction'

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
