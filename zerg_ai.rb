require 'RProxyBot/RProxyBot/proxybot'
require 'condition'
require 'ai_helpers'
require 'state'
require 'ostruct'

module AI
	class	ZergAI
    include RProxyBot
		include	RProxyBot::Constants
    include RProxyBot::Constants::UnitTypes

    include ZergAIHelpers
    include ConditionSyntax
	  
    attr_accessor :state
    attr_accessor :strategy_steps

    #Start of the game
    def start(game)
      self.state = State.new(game)
      self.strategy_steps = []

      game.command_queue.push(Commands::GameSpeed, 0)

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

          minerals = starcraft.units.minerals.sort do |a, b|
            b.distance_to(center) <=> a.distance_to(center)
          end

          player.workers.select(&:idle?).each do |worker|
            worker.mine(minerals.pop)
          end
        end
      end

      #When there is not enough supply an overlord should be spawned
      strategy_step "Spawn an overlord" do
        precondition do
          player.minerals >= 100 && player.supply_total >= player.supply_used #not smart
        end

        postcondition do
          false #this step should be repeated
        end

        order do
          spawn Overlord
        end
      end

      #When there is less than 5 supply and a spawning pool does not exist, a drone should be spawned
      strategy_step "Spawn a drone" do
        precondition do
          player.minerals >= 50 && player.supply_total < 5
        end

        postcondition do
          false #this step should be repeated
        end

        order do
          spawn Drone
        end
      end

      #At 5 supply, 200 minerals a spawning pool should be made
      strategy_step "Make a spawning pool at 5 supply" do
        precondition do
          player.minerals > 200 && player.supply_total >= 5
        end

        postcondition do
          player.units.values.any? {|u| u.type == SpawningPool && u.is_completed?}
        end

        order do
          player.workers.first.build(SpawningPool, build_location(SpawningPool))
        end
      end

      #When there is a spawning pool and enough minerals and supply, a zergling should be made
      strategy_step "Make zerglings" do
        precondition do
          player.minerals > 50 && player.supply_left >= 1
        end

        precondition do #a spawning pool exists
          player.units.values.any? {|u| u.type == SpawningPool && u.is_completed?}
        end

        postcondition do
          false #this step should be repeated
        end

        order do
          while (player.minerals > 50 && player.supply_left >= 1) do
            spawn Zergling #spawn many zerglings in one frame
          end
        end
      end

      #When there are 5 zerglings, they should attack
      strategy_step "Attack!" do
        precondition do
          player.get_all_by_unit_type(Zergling).count >= 5
        end

        postcondition do
          false #just keep on doin' it
        end

        order do
          #yeah.. about that..
        end
      end
    end
  end #class ZergAI

  p = RProxyBot::ProxyBot.instance
  p.run(12345,"1","1","1","1", 20, ZergAI.new)
end #module AI
