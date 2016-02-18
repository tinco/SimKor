require 'condition'
require 'ai_helpers'
require 'state'
require 'strategy'
require 'ostruct'
require 'forwardable'

class ZergAI < Bwapi::Bot
  attr_accessor :strategy, :state

  #Start of the game
  def on_start
    game.local_speed = 0
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
        step.execute
      end
    end
  end

  #makes the strategy consisting of steps
  def initialize_strategy
    #Basic Strategy:
    strategy_step "Every idle worker should mine" do
      precondition do
        true #No requirements
      end

      postcondition do
        false #this step should be repeated
      end

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
      precondition do
        player.minerals >= 50 && player.supply_used < 10
      end

      postcondition do
        false #this step should be repeated
      end

      order do
        spawn UnitType.Zerg_Drone
      end
    end

    #When there is not enough supply an overlord should be spawned
    strategy_step "Spawn an overlord" do
      precondition do
        player.minerals >= 100 && player.supply_total <= player.supply_used #not smart
      end

      progresscondition do
        player.units.values.any? {|unit| unit.issued_orders.first && unit.issued_orders.first.name == "Spawn Overlord"}
      end

      postcondition do
        false #this step should be repeated
      end

      order do
        spawn UnitType.Zerg_Overlord
      end
    end

    strategy_step "Go scout" do
      precondition do
        false #player.units.values.count(&:worker?) >= 5
      end

      postcondition do
        #arrived_at_unexplored_enemy_location
      end

      order do
        #scout = player.workers.select {|w|w.issued_orders.first.name == "Mine" }.first
        #scout.issued_orders = []
        #scout.move_to unexplored_enemy_location
      end
    end

    #At 5 supply, 200 minerals a spawning pool should be made
    strategy_step "Make a spawning pool at 5 supply" do
      precondition do
        player.minerals > 200 && player.supply_total >= 10
      end

      postcondition do
        player.units.values.any? {|u| u.type == UnitType.Zerg_Spawning_Pool}
      end

      progresscondition do
        player.units.values.any? {|unit| unit.issued_orders.first && unit.issued_orders.first.name == "Build SpawningPool"}
      end

      order do
        player.workers.first.build(SpawningPool, build_location(UnitType.Zerg_Spawning_Pool))
      end
    end

    #When there is a spawning pool and enough minerals and supply, a zergling should be made
    strategy_step "Make zerglings" do
      precondition do
        player.minerals > 50 && player.supply_left >= 2
      end

      precondition do #a spawning pool exists
        player.units.values.any? {|u| u.type == UnitType.Zerg_Spawning_Pool }
      end

      postcondition do
        false #this step should be repeated
      end

      order do
        while (player.minerals > 50 && player.supply_left >= 2 && player.larva_available?) do
          spawn UnitType.Zerg_Zergling #spawn many zerglings in one frame
        end
      end
    end

    #When there are 5 zerglings, they should attack
    strategy_step "Attack!" do
      precondition do
        player.get_all_by_unit_type(UnitType.Zerg_Zergling).count >= 5
      end

      postcondition do
        false #just keep on doin' it
      end

      order do
        player.get_all_by_unit_type(UnitType.Zerg_Zergling).reject(&:dead?).select(&:idle?).each do |z|
          attack_nearest_enemy(z)
        end
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
