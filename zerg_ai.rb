require 'condition'
require 'ai_helpers'
require 'zerg_ai_helpers'
require 'state'
require 'strategy'
require 'ostruct'
require 'forwardable'

class ZergAI < Bwapi::Bot
  attr_accessor :strategy, :state

  #Start of the game
  def on_start
    game.local_speed = 0

    puts "Analyzing map..."
    Bwapi::BWTA.readMap
    Bwapi::BWTA.analyze
    puts "Map data ready"

    @state = AI::State.new(game)
    @strategy = ZergStrategy.new(state)
  rescue Exception => e
    puts "-------------"
    puts e.message
    puts e.backtrace
    puts "-------------"
    sleep 5
    exit
  end

  #Every frame
  def on_frame
    state.update
    strategy.execute
  rescue Exception => e
    puts "-------------"
    puts e.message
    puts e.backtrace
    puts "-------------"
    sleep 5
  end #on_frame
end

class ZergStrategy
  extend Forwardable

  include AI::Helpers
  include AI::ZergHelpers
  include AI::ConditionSyntax

  attr_accessor :state
  attr_accessor :strategy_steps

  delegate player: :state, 
           units: :state,
           players: :state,
           starcraft: :state 

  def initialize(state)
    @strategy_steps = {}
    @state = state
    initialize_strategy
  end

  #execute a step that is not satisfied, and execute it, if its requirements are met.
  def execute
    strategy_steps.values.reject {|s|s.satisfied? || s.in_progress?}.each do |step|
      if step.requirements_met?
        puts "Executing: #{step.name}"
        step.execute
      end
    end
  end

  #makes the strategy consisting of steps
  def initialize_strategy
    main_position = player.command_centers.first.position
    _, *unscouted_bases = BWTA.start_locations.to_a.map(&:position).sort do |a, b|
      main_position.getDistance(b) <=> main_position.getDistance(a)
    end.reverse
    overlord_target = nil

    #Basic Strategy:
    strategy_step "Every idle worker should mine" do
      precondition { player.workers.any? &:idle? }

      postcondition { false } #this step should be repeated

      order do
        center = player.command_centers.first

        minerals = state.units.values.select{|u| u.type.mineral_field? }.sort do |a, b|
          b.distance(center) <=> a.distance(center)
        end

        player.workers.select(&:idle?).each do |worker|
          worker.mine(minerals.pop)
        end
      end
    end

    #When there is less than 5 supply and a spawning pool does not exist, a drone should be spawned
    strategy_step "Spawn a drone" do
      precondition { player.minerals >= 50 && player.supply_used < 10 }

      postcondition { false } #this step should be repeated

      order { spawn UnitType.Zerg_Drone }
    end

    #When there is not enough supply an overlord should be spawned
    strategy_step "Spawn an overlord" do
      precondition { player.minerals >= 100 && player.supply_total <= player.supply_used && player.larva_available? } #not smart

      progresscondition { player.units.values.any? {|unit| unit.has_order? "Spawn Overlord" } }

      postcondition { false }#this step should be repeated

      order { spawn UnitType.Zerg_Overlord }
    end

    strategy_step "Early overlord scout" do
      overlord = nil
      target = nil

      precondition do
        overlords = player.get_all_by_unit_type(UnitType.Zerg_Overlord)
        if overlords.count == 1
          overlord = overlords.first
          target = unscouted_bases.shift
          overlord_target = target
          true
        end
      end

      progresscondition { overlord && target }

      postcondition { overlord.position == target if overlord }

      order { overlord.move(target) if overlord }
    end

    strategy_step "Drone scout" do
      drone_scout = nil
      target = nil

      precondition do
        if player.get_all_by_unit_type(UnitType.Zerg_Spawning_Pool).count > 0 && target = unscouted_bases.shift
          drone_scout = player.workers.first
          true
        end
      end

      order do
        # TODO why is if drone_scout necessary?
        drone_scout.move(target) if drone_scout
      end
    end

    #At 5 supply, 200 minerals a spawning pool should be made
    strategy_step "Make a spawning pool at 5 supply" do
      precondition { player.minerals > 200 && player.supply_total >= 10 }

      postcondition { player.units.values.any? {|u| u.type == UnitType.Zerg_Spawning_Pool} }

      progresscondition { player.units.values.any? {|u| u.has_order? "Build SpawningPool" } }

      order do
        player.workers.first.build(UnitType.Zerg_Spawning_Pool, build_location(UnitType.Zerg_Spawning_Pool))
      end
    end

    #When there is a spawning pool and enough minerals and supply, a zergling should be made
    strategy_step "Make zerglings" do
      precondition { player.minerals > 50 && player.supply_left >= 2 && player.larva_available? }

      precondition { player.get_all_by_unit_type(UnitType.Zerg_Spawning_Pool).count > 0 }

      postcondition { false } #this step should be repeated

      order do
        while (player.minerals > 50 && player.supply_left >= 2 && player.larva_available?) do
          spawn UnitType.Zerg_Zergling #spawn many zerglings in one frame
        end
      end
    end

    strategy_step "Move in!" do
      precondition { zerglings.count >= 1 && enemy.units.count == 0 }

      postcondition { false }

      order do
        target = unscouted_bases.shift || overlord_target

        zerglings.each do |z|
          puts "Ordering zerglings to move"
          z.move(target)
        end
      end
    end

    #When there are 5 zerglings, they should attack
    strategy_step "Attack!" do
      precondition { zerglings.count >= 5 && enemy.units.count > 0 }

      postcondition { false } #just keep on doin' it

      order do 
        puts "Ordering zerglings to attack"
        zerglings.each { |z| attack_nearest_enemy(z) }
      end
    end
  end

  #make the methods of the state available here
  def method_missing(name, *params)
    if state.respond_to? name
      state.send name, *params
    else
      super
    end
  end
end #class ZergAI
