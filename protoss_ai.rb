require 'RProxyBot/RProxyBot/proxybot.rb'
require 'util.rb'

module AI
  class ProtossAI
    include RProxyBot
    include RProxyBot::Constants

    attr_accessor :starcraft

    attr_accessor :player, :center, :minerals, :workers
    
    def start(game)
      @starcraft = game
      @player = starcraft.player
      @center = player.command_centers.first
      @workers = player.workers

      @minerals = starcraft.units.minerals.sort do |a, b|
        b.distance_to(center) <=> a.distance_to(center)
      end

      workers.each do |w|
        w.right_click_unit(minerals.pop)
      end

      starcraft.command_queue.push(Commands::GameSpeed, 0)
      puts "end of start"
    end #start

    def on_frame
      if (player.minerals	>=	50 &&
          player.supply_total	>	player.supply_used)
        #center.train_timer	== 0
        then
        center.train_unit(UnitTypes::Probe)
      end

      #If	max	supply is	reached, run this	(building	a	pylon	if needed)
      if (player.supply_used >=	player.supply_total)

        puts "in supply	check	loop"

        build_pylon	=	true

        #Check for any pylons	being	built
        starcraft.player.units.values.each do	|u|

          if (u.type ==	UnitTypes::Pylon)

            puts "er is	een	pylon..."

            if !(u.build_timer ==	0)
              puts "...in	aanbouw"
              build_pylon	=	false
            end
          end

        end

        if (build_pylon	== true)
          puts "ik ga	bouwen"
          x	=	100
          y	=	100
          #while(!map.buildable?(x,	y))	do
          #	x	+= 1
          #	y	+= 1
          #end
          puts "entering if	loop"
          if (center.x < minerals.last.x)
            puts "center.x < minerals.last"
            pylon_x	=	((center.x)	-	6	)
            puts "pylon_x	=	((center.x)	-	6	)"
          else
            puts "else"
            pylon_x	=	((center.x)	+	6	)
            puts "pylon_x	=	((center.x)	+	6	)"
          end
          puts "ga bouwen	dan	KUT" #<-- haha :P
          workers.first.build(UnitTypes::Pylon,	pylon_x, center.y)
          puts "ik ga	echt bouwen"
        end

      end						

      player.workers.each	do |worker|
        if worker.order	== Orders::PlayerGuard
          worker.right_click_unit(minerals.last)
        end
      end
    end #on_frame
  end #class ProtossAI
  p = RProxyBot::ProxyBot.instance
  p.run(12345,"1","1","1","1", 20, ProtossAI.new)
end #module AI
