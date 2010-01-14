require 'RProxyBot/RProxyBot/proxybot'
require 'ai_helpers'
require 'zerg_ai_helpers'

module AI
	class	ZergAI
    include RProxyBot
		include	RProxyBot::Constants
    include ZergAIHelpers
	  
    attr_accessor :rc
		
    attr_accessor :starcraft

    attr_accessor :player, :center, :minerals, :workers
    attr_accessor :larvae, :eggs, :buildorders, :supply_plus
    attr_accessor :spent_minerals, :issued_orders
    
    def start(game)
      @starcraft = game
      @player = starcraft.player
      @center = player.command_centers.first
      @workers = player.workers
			@larvae = player.larvae
			@eggs = player.eggs

      @minerals = starcraft.units.minerals.sort do |a, b|
        b.distance_to(center) <=> a.distance_to(center)
      end

      workers.each do |w|
        w.right_click_unit(minerals.pop)
      end

      starcraft.command_queue.push(Commands::GameSpeed, 0)

      buildOrder = BuildOrder.new(18,UnitTypes::SpawningPool,200,3,2)
      @buildorders = Array.new
      @buildorders.push(buildOrder)
      buildOrder = BuildOrder.new(16,UnitTypes::SpawningPool,200,3,2)
      @buildorders.push(buildOrder)
      buildOrder = BuildOrder.new(20,UnitTypes::SpawningPool,200,3,2)
      @buildorders.push(buildOrder)
      puts"Eerste order: #{@buildorders.first.supply}"
      @issued_orders = Array.new
      @spent_minerals = 0

      puts"starting getRestrictedCoords"
      @rc = restricted_coords
      @rc.uniq!
      puts"testje (#{@rc.last.x},#{@rc.last.y})"

      @supply_plus = 18 #TODO dit is niet een goede naam
      
      puts"Spawningpool cost: #{Unit.mineral_cost(UnitTypes::SpawningPool)}"
      puts"RestrictedCoords na uniq!: #{@rc.length}"  
      sleep(0.5)

      center.train_unit(UnitTypes::Probe)
			sleep(0.5) #We wait	a	few	frames to	make sure	the
								 #orders have	been processed for the

    end

    def on_frame
      begin
        #gebruikt buildorder
        #bouw Overlord als alle supply in gebruik is en er meer dan 100 minerals zijn
        if (player.supply_used >= (supply_plus - 2) && player.minerals >= 100)
          puts"maak overlord"
          if !(player.larvae.empty? == true)
            player.larvae.first.train_unit(UnitTypes::Overlord)
            self.supply_plus += 16
          end				    
        end

        #bouw drone als de supply voor de volgende buildorder nog niet bereikt is
        #!!ERROR!! Script crasht hier als buildOrderList leeg is
        if (player.supply_used < buildorders.first.supply && 
            player.supply_used < (supply_plus - 2) &&
            (player.minerals - spent_minerals)	>= 50 )
          puts"bouw drone"
          if !(player.larvae.empty? == true)
            player.larvae.first.train_unit(UnitTypes::Drone)
          end

        end

        #als de buildorder supply is bereikt en voldoende minerals, bouw gebouw
        if (player.supply_used == buildorders.first.supply && player.minerals	>= buildorders.first.cost)
          puts"buildStructure"
          issued_orders.push(build_structure(center.x,center.y,4,4,buildorders.first.u,buildorders.first.v,@rc))
          puts"buildStructure complete"
          puts"issuedOrders.last.cost: #{issued_orders.last.cost}, issuedOrders.last.workerId: #{issued_orders.last.workerId}"
          spent_minerals += issued_orders.last.cost
          puts"#buildOrderList: #{buildorders.length}, supply: #{buildorders.first.supply}, shifting"
          buildorders.shift
          puts"buildOrderList.shift complete"
        end

        #presentWorkers = player.workers

        puts"#{issued_orders.length}"
        issued_orders.each do |order|
          if (order.type == player.units[order.workerId].type)
            puts"done"
            puts"spentminerals #{spentMinerals}"
            spent_minerals -= order.cost
            puts"spentminerals #{spentMinerals} na deductie"
            issued_orders.delete_if{|x| x.workerId == order.workerId}
          end

        end

        player.workers.each	do |worker|

          #playerputs "Ga idle drones checken"

          if worker.order	== Orders::PlayerGuard

            #puts "Idle drone gevonden"

            worker.right_click_unit(minerals.last)

            #puts "Idle drone opdracht gegeven"

          end
        end

        sleep 0.05 #FIXME is dit nodig?
      rescue Exception => e
        puts "-------------"
        puts e.message
        puts e.backtrace
        puts "-------------"
      end
    end #on_frame
  end #class ZergAI
  p = RProxyBot::ProxyBot.instance
  p.run(12345,"1","1","1","1", 20, ZergAI.new)
end #module AI
