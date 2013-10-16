#require_relative 'Mafia_Sim'
require_relative 'Faction'

class Village
	def initialize(faction_hash)
		@factions = Array.new
		faction_hash.each do |faction, role_hash|
			case faction
			when :Town
				@factions.concat([Town.new(self, faction, role_hash)])
			when :Mafia
				@factions.concat([Mafia.new(self, faction, role_hash)])
			end
		end
		@scum_positive = Array.new()
		@dead = Array.new()
	end

	def count_alive_village
		alive = 0
		@factions.each do |f|
			alive += f.count_alive_faction
		end
		alive
	end

	def each_player(&block)
		@factions.each do |f|
			f.players.each(&block)
		end
	end

	def each_player_with_index(&block)
		i = 0
		@factions.each do |f|
			f.players.to_enum.with_index(i).each(&block)
			i += f.count_alive_faction
		end
	end

	def lynch
		@scum_positive.each do |p|
			if p.alive
				p.alive = false
				if $DEBUG
					puts "Lynched: #{p} because of investigation"
				end
				@scum_positive.delete(p)
				return
			else
				@scum_positive.delete(p)
			end
		end

		target = Random.rand(count_alive_village)
		each_player do |p|
			if p.alive
				if target == 0
					p.alive = false
					if $DEBUG
						puts "Lynched: #{p}"
					end
					return
				else
					target -= 1
				end
			end
		end
	end

	def night_actions
		#Set mafia kill
		@factions.each do |f|
			if f.type == :Mafia
				f.set_killer
			end
		end

		#Gather actions
		@actions = Hash.new()
		each_player do |p|
			if (p.alive && (p.has_action || p.has_kill))
				p_actions = p.action(self)
				puts "actions[#{p_actions.length}]: #{p_actions[0].type} ... #{p_actions[p_actions.length - 1].type}"
				p_actions.each do |a|
					if $DEBUG
						puts "Gathered action type: #{a.type}, actor: #{a.actor.faction_type}, target: #{a.target.faction_type}"
					end
					@actions.merge!({a.type  => [a]}) {|key, old_val, new_val| [old_val, new_val]}
					if a.type == :Kill && p.faction_type == :Mafia
						p.has_kill = false
					end
				end
			end
		end

		#Evaluate actions
		if @actions.has_key?(:Block)
			@actions[:Block].each_with_index do |a,i|
				if $DEBUG
					puts "Trying to block #{a.target} actor alive?: #{a.actor.alive} blocked? #{a.actor.blocked}"
				end
				if (!a.executed && a.actor.alive && a.actor.blocked <= 0)
					a.executed = true
					a.target.blocked += 1
					undo_block(a)
					if $DEBUG
						puts "Blocked: #{a.target}"
					end
				end
			end
		end
		if @actions.has_key?(:Protect)
			@actions[:Protect].each do |a|
				if $DEBUG
					puts "Trying to protect #{a.target} actor alive?: #{a.actor.alive} blocked? #{a.actor.blocked}"
				end
				if (a.actor.alive && 
					a.actor.blocked <= 0)
					a.executed = true
					a.target.protected += 1
					if $DEBUG
						puts "Protected: #{a.target}"
					end
				end
			end
		end
		if @actions.has_key?(:Kill)
			@actions[:Kill].each do |a|
				if $DEBUG
					puts "Trying to kill #{a.target} actor alive?: #{a.actor.alive} blocked? #{a.actor.blocked} target protected? #{a.target.protected}"
				end
				if (a.actor.alive && a.actor.blocked <= 0 && a.target.protected <= 0)
					a.target.alive = false
					if $DEBUG
						puts "Killed attempted: #{a.target}"
					end
				elsif a.actor.alive && a.actor.blocked <= 0
					a.target.protected -= 1
					if $DEBUG
						puts "Killed: #{a.target}"
					end
				end
			end
		end
		if @actions.has_key?(:Investigate)
			@actions[:Investigate].each do |a|
				if $DEBUG
					puts "Trying to investigate #{a.target} actor alive?: #{a.actor.alive} blocked? #{a.actor.blocked}"
				end
				if (a.actor.alive && a.actor.blocked <= 0)
					if $DEBUG
						puts "Investigated: #{a.target} came up: #{a.target.investigate}"
					end
					if a.target.investigate != :Town
						@scum_positive.concat([a.target])
					end
				end
			end
		end

		#Clean-up non permanent actions
		if @actions.has_key?(:Protect)
			@actions[:Protect].each do |a|
				if a.executed
					a.target.protected = 0
				end
			end
		end
		if @actions.has_key?(:Block)
			@actions[:Block].each do |a|
				if a.executed
					a.target.blocked = 0
				end
			end
		end
	end

	def undo_block(action)
		if @actions.has_key?(:Block)
			@actions[:Block].each do |a|
				if a.executed && a.actor == action.target
					a.target.blocked -= 1
					a.executed = false
					redo_block(a)
				end
			end
		end
	end

	def redo_block(action)
		if @actions.has_key?(:Block)
			@actions[:Block].each do |a|
				if !a.executed && a.actor == action.target
					a.target.blocked += 1
					a.executed = false
					undo_block(a)
				end
			end
		end
	end

	def print_details
		n = 0
		factions.each do |f|
			f.players.each do |p|
				if p.alive
					puts "Player#{n}- Role: #{p.class} Alive: #{p.alive} Blocked: #{p.blocked} Has action?: #{p.has_action} Protected: #{p.protected}"
					n += 1
				end
			end
		end
	end

	attr_accessor :factions
	attr_accessor :dead
end

# TOWN_SETUP = {:Townie => 10, :Doctor => 1}
# MAFIA_SETUP = {:Goon => 2}
# VILLAGE_SETUP = {:Town => TOWN_SETUP, :Mafia => MAFIA_SETUP}
# village = Village.new(VILLAGE_SETUP)

# village.each_player_with_index do |p,i|
# 	puts "player #{i}: #{p}"
# end