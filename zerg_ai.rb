require 'RProxyBot/RProxyBot/proxybot'
require 'ai_helpers'
require 'zerg_ai_helpers'
require 'state'

module AI
	class	ZergAI
    include RProxyBot
		include	RProxyBot::Constants
    include RProxyBot::Constants::UnitTypes

    include ZergAIHelpers
	  
    attr_accessor :state
    attr_accessor :strategy_steps

    #Start of the game
    def start(game)
      self.state = State.new(game)

      game.command_queue.push(Commands::GameSpeed, 0)

      perfect_split

      spawn Drone

      initialize_strategy
    end

    #Every frame
    def on_frame
      begin
        state.update
        execute_strategy
      rescue Exception => e
        puts "-------------"
        puts e.message
        puts e.backtrace
        puts "-------------"
        sleep 10
      end
    end #on_frame

    #execute a step that is not satisfied, and execute it, if its requirements are met.
    def execute_strategy
      strategy_steps.reject(&:satisfied?).each do |step|
        if step.requirements_met?
          step.execute
        end
      end
    end

    #makes the strategy consisting of steps
    def initialize_strategy
      self.strategy_steps = []

      #Basic Strategy:
      #Every idle worker should mine:
      strategy_steps << StrategyStep.new([Condition::True], [Condition::False]) do
        center = player.command_centers.first

        minerals = starcraft.units.minerals.sort do |a, b|
          b.distance_to(center) <=> a.distance_to(center)
        end
        
        player.workers.select(&:idle?).each do |worker|
          worker.mine(minerals.pop)
        end
      end
      #At 5 supply, 200 minerals a spawning pool should be made
      mineral_condition = Condition.new {player.minerals > 200}
      supply_condition = Condition.new {player.minerals >= 5}
      post_condition = Condition.new do
        not player.units.values.select {|u| u.type == SpawningPool && u.is_completed?}.empty?
      end

      strategy_steps << StrategyStep.new([mineral_condition, supply_condition],[post_condition]) do
        puts "ik ga een spawning pool maken"
      end
      #When there is a spawning pool and enough minerals and supply, a zergling should be made
      #When there is not enough supply an overlord should be spawned
      #When there are 5 zerglings, they should attack
    end

    #build a unit
    def spawn(unit_type)
      player.larvae.first.spawn(unit_type)
    end

    #execute a perfect split
    def perfect_split
      center = player.command_centers.first

      minerals = starcraft.units.minerals.sort do |a, b|
        b.distance_to(center) <=> a.distance_to(center)
      end

      player.workers.each do |worker|
        worker.mine(minerals.pop)
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

    #A step in a strategy with its post and pre conditions
    class StrategyStep
      attr_accessor :postconditions, :preconditions, :order

      def initialize(preconditions, postconditions, &order)
        self.postconditions = postconditions
        self.preconditions = preconditions
        self.order = order
      end

      def execute
        order.call
      end

      #A step has been satisfied if all its postconditions have been met
      def satisfied?
        postconditions.reject(&:met?).empty?
      end
        
      #A step is ready to be executed if all its preconditions have been met
      def requirements_met?
        preconditions.reject(&:met?).empty?
      end
    end #class StrategyStep

  end #class ZergAI

  #Conditions are procs that should return a boolean value
  class Condition < Proc
    def met?
      self.call
    end

    False = Condition.new {false}
    True = Condition.new {true}
  end #class Condition

  p = RProxyBot::ProxyBot.instance
  p.run(12345,"1","1","1","1", 20, ZergAI.new)
end #module AI
