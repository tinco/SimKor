require 'RProxyBot/RProxyBot/proxybot'
require 'ai_helpers'
require 'zerg_ai_helpers'

module AI
	class	ZergAI
    include RProxyBot
		include	RProxyBot::Constants
    include RProxyBot::Constants::UnitTypes

    include ZergAIHelpers
	  
    attr_accessor :starcraft

    #Start of the game
    def start(game)
      @starcraft = game

      initialize_state

      perfect_split

      spawn Drone

      initialize_strategy
    end

    #Every frame
    def on_frame
      begin
        execute_strategy
      rescue Exception => e
        puts "-------------"
        puts e.message
        puts e.backtrace
        puts "-------------"
        sleep 10
      end
    end #on_frame

    private
    #execute a step that is not satisfied, and execute it, if its requirements are met.
    def execute_strategy
      strategy_steps.reject(&:satisfied?).each do |step|
        if step.requirements_met?
          step.execute
        end
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

      def satisfied?
        postconditions.collect(&:met?).empty?
      end

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
