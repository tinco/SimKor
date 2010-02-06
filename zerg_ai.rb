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

    #execute a perfect split
    def perfect_split
    end

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
    end

    #build a unit
    def spawn(unit_type)
      player.larvae.first.spawn(unit_type)
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

      def initialize(postconditions, preconditions, &order)
        self.postconditions = postconditions
        self.preconditions = preconditions
        self.order = order
      end

      def execute
        order.call
      end

      #A step has been satisfied if all its postconditions have been met
      def satisfied?
        postconditions.collect(&:met?).empty?
      end
        
      #A step is ready to be executed if all its preconditions have been met
      def requirements_met?
        preconditions.collect(&:met?).empty?
      end
    end #class StrategyStep

    #Conditions are procs that should return a boolean value
    class Condition < Proc
      def met?
        self.call
      end
    end #class Condition
  end #class ZergAI

  p = RProxyBot::ProxyBot.instance
  p.run(12345,"1","1","1","1", 20, ZergAI.new)
end #module AI
