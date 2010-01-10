require 'RProxyBot/RProxyBot/proxybot.rb'
require 'util.rb'

module AI
	class	ZergAI
    include RProxyBot
		include	RProxyBOT::Constants
		@@rc = []		
	  
	  #this method provides an array of mineralspots that are 
	  #within a 9 unit radius of the command center
	  def self.giveMineralSpots
      ProxyBot.instance.units.minerals.select do |u|
        u.distance_to(ProxyBot.instance.player.command_centers.first)<9
      end
    end
    
    def self.giveVespeneGeysers
        ProxyBot.instance.units.vespene_geysers.select do |u|
        u.distance_to(ProxyBot.instance.player.command_centers.first)<9
      end
    end
    
      #returns array of tile-coordinates of specified building
      #building location (x,y), size a*b
    def self.getBuildingCoordinates(x,y,a,b)
        puts"building #{a}x#{b} at location (#{x},#{y})"
        coords = Array.new
        (0..b-1).each do |j|
          
          (0..a-1).each do |i|
          
            co = Coordinate.new(x+i,y+j)
            coords.push(co)
          end
          
        end
      puts"*getBuildingCoordinates* returning array of building coordinates"
      coords
    end
    
 
    def self.checkSite(x,y,u,v)
      #checks if the  target building can be built on tile (x,y), using restricted tileset rc
      #building has size u*v
      #puts"checking Site"
      buildable = true
      coords = Array.new
      freetiles = Array.new
      (0..v-1).each do |j|
        
        (0..u-1).each do |i|
        
          co = Coordinate.new(x+i,y+j)
          coords.push(co)
        end
      end
      
      #subtract the restricted coords array from the building_site_coordinates array
      #puts"freetiles = coords - rc"
      freetiles = coords - @@rc
      #puts"freetiles = coords - rc DONE"
      
      #site is only buildable if all tiles are buildable
      if (freetiles.length < u+v)
        buildable = false
      end
      buildable
      
    end

    def self.makeCoordArray(x,y,a,b,u,v)
      puts"makeCoordArray called"
      coords = Array.new
      #(x,y) are CC coords, (a,b) are resource (mineral/geyser) coords
      #u*v are dimensions of the tiles
      #providing a coordinate and another coordinate/rester, this method provides an array of coordinates
      #that fall within the coordinate and raster
       
      ([y,b].min..[y,(b+v)].max).each do |j|
        
        ([x,a].min..[x,(a+u)].max).each do |i|
          
          #create a coordinate with the x and y values, push on array
          co = Coordinate.new(i,j)
          coords.push(co)
        end        
      
      end
   
      coords  
      
    end
	  
  
	  def self.getRestrictedCoords
	    #retrieve array of mineralspots close to CC
	    mineralspots = giveMineralSpots
	    vespenespots = giveVespeneGeysers
	    
	    #array of coords of geyser (1 geyser at the moment!)
	    vespenecoords = Array.new
      vespenecoords = getBuildingCoordinates(vespenespots.last.x,vespenespots.last.y,4,2)
	    
	    #create an array that will contrain all restricted coordinates
	    rescoords = Array.new
      #for every mineralspot, and array of restricted coordinates retrieved
	    done = false
	    while (done == false)
	      rescoords.concat(makeCoordArray(ProxyBot.instance.player.command_centers.first.x,ProxyBot.instance.player.command_centers.first.y,mineralspots.last.x,mineralspots.last.y,2,1))
	      mineralspots.pop
	      done = mineralspots.last.nil?
	    end
	    
	    done = false

	    while (done == false)
	      rescoords.concat(makeCoordArray(ProxyBot.instance.player.command_centers.first.x,ProxyBot.instance.player.command_centers.first.y,vespenecoords.last.x,vespenecoords.last.y,4,2))
	      vespenecoords.pop
	      done = vespenecoords.last.nil?
	    end
	     puts"end of getRestrictedCoords, rescoords.length #{rescoords.length}"
	     rescoords
    end
	  
	  def self.getSpiralCoords(x,y,a,b,n)
	    #provides an array of coordinates around 
	    #the a*b tileset located at coordinate (x,y)
	    #distance spiral<->tileset is n
	    
	    #calculate the starting position for the spiral
        xLoc = x-n
        yLoc = y-n
        
        #The size of the source building determines the size of the spiral
        rasterSizeX = (2*n)+a-1
        rasterSizeY = (2*n)+b-1
        kanBouwen = true
        tiles = Array.new
        
          #Top row of tiles        
          (0..(rasterSizeX)).each do |i|
            xCoordinaat = xLoc + i
            co = Coordinate.new(xCoordinaat,yLoc)
            tiles.push(co)
          end
          
          #Right row of tiles (excluding top right)          
          (1..(rasterSizeY)).each do |i|
            yCoordinaat = yLoc + i
            co = Coordinate.new(xLoc+rasterSizeX,yCoordinaat)
            tiles.push(co)
          end
          
          #Bottom row of tiles (excluding bottom right)  
          (0..(rasterSizeX-1)).each do |i|
            xCoordinaat = xLoc + i
            co = Coordinate.new(xCoordinaat,yLoc+rasterSizeY)
            tiles.push(co)
          end
          
          #Left row of tiles (excluding bottom left and top left)
          (1..(rasterSizeY-1)).each do |i|
            yCoordinaat = yLoc + i
            co = Coordinate.new(xLoc,yCoordinaat)
            tiles.push(co)
          end
        puts"*getSpiralCoords complete*"        
        puts"Tiles.length #{tiles.length}"
        tiles
	  end
	  
	  def self.getBuildableCoords(x,y,a,b,u,v,rc)
	    #returns all coordinates where the structure with size u*v
	    #can be built around source building a*b at location (x,y)
	    #bc are buildable coordinates
	    bc = Array.new
	    
	    #n is iteratie nr. Voor gemak even hoogte van gebouw (zodat hij op horizontale rij geplaatst kan worden)
      n = v
      canBuild = false
      noMoreCoordsAvail = false
      #sc are spiral coordinates
      #First receive the spiral of coords around source building
      sc = Array.new
      sc = getSpiralCoords(x,y,a,b,n)
      while (noMoreCoordsAvail == false)
        #For each coordinate in the spiral, check if the building can be placed
        #puts"entering checkSite"
        if(checkSite(sc.last.x,sc.last.y,u,v) == true)
          co = Coordinate.new(sc.last.x,sc.last.y)
          bc.push(co)
        end
        
        sc.pop
	      noMoreCoordsAvail = sc.last.nil?
             
      end
      puts"*getBuildableCoords complete*"
	    bc  
	    
	  end
	  
	  def self.buildStructure(x,y,a,b,u,v,rc)
	    #(x,y), source bld coords, size a*b
	    #target building size u*v
	    #rc are restricted coords between minerals and CC
	    #returns an order object containing order info
	  
	    bc = Array.new
	    bc = getBuildableCoords(x,y,a,b,u,v,rc)
      ProxyBot.instance.player.workers.first.build(UnitTypes::SpawningPool,	bc.last.x, bc.last.y)
      puts"voor brc"
      brc = getBuildingCoordinates(bc.last.x, bc.last.y,u,v) 
      puts"brc complete"
      @@rc.concat(brc)
      puts"concat rc complete"
      @@rc.uniq!
      puts"uniq rc complete"
      io = IssuedOrder.new(ProxyBot.instance.player.workers.first.id, Unit.mineral_cost(UnitTypes::SpawningPool), UnitTypes::SpawningPool)
      puts"#{io.workerId},#{io.cost}"
      io
      
    end
		
		def	self.start
			Thread.new do
				starcraft	=	ProxyBot.instance.game
				player = starcraft.player
				workers	=	player.workers
				center = player.command_centers.first
				larvae = player.larvae
				eggs = player.eggs
				minerals = starcraft.units.minerals.sort do	|a,	b|
					b.distance_to(center)	<=>	a.distance_to(center)
				end
			
			  workers.each do	|w|
					w.right_click_unit(minerals.pop)
				end
        
        CommandQueue.push(Constants::Commands::GameSpeed,0)
        
        buildOrder = BuildOrder.new(18,UnitTypes::SpawningPool,200,3,2)
        buildOrderList = Array.new
        buildOrderList.push(buildOrder)
        buildOrder = BuildOrder.new(16,UnitTypes::SpawningPool,200,3,2)
        buildOrderList.push(buildOrder)
        buildOrder = BuildOrder.new(20,UnitTypes::SpawningPool,200,3,2)
        buildOrderList.push(buildOrder)
        puts"Eerste order: #{buildOrderList.first.supply}"
        issuedOrders = Array.new
        spentMinerals = 0
        
        puts"starting getRestrictedCoords"
        @@rc = getRestrictedCoords
        @@rc.uniq!
        puts"testje (#{@@rc.last.x},#{@@rc.last.y})"
        supplyplus = 18
        puts"Spawningpool cost: #{Unit.mineral_cost(UnitTypes::SpawningPool)}"
        puts"RestrictedCoords na uniq!: #{@@rc.length}"  
        sleep(0.5)

				center.train_unit(UnitTypes::Probe)
				sleep(0.5) #We wait	a	few	frames to	make sure	the
									 #orders have	been processed for the
									 #the	loop (which	starts immediately)

				last_frame = -1
				
				  while(player.race == "Zerg")
				    if(last_frame	== starcraft.frame)
  						sleep(0.05)
  						#puts "Sleeping for 0.05"
  					else
  					  last_frame = starcraft.frame
             
					    #gebruikt buildorder
					    #bouw Overlord als alle supply in gebruik is en er meer dan 100 minerals zijn
					    if (player.supply_used >= (supplyplus-2) && player.minerals >= 100)
					      puts"maak overlord"
					      if !(player.larvae.empty? == true)
  						    player.larvae.first.train_unit(UnitTypes::Overlord)
  						    supplyplus = supplyplus + 16
  						  end				    
					    end
					    
				      #bouw drone als de supply voor de volgende buildorder nog niet bereikt is
				      #!!ERROR!! Script crasht hier als buildOrderList leeg is
					    if (player.supply_used < buildOrderList.first.supply && player.supply_used < (supplyplus-2) && (player.minerals-spentMinerals)	>= 50 )
					      puts"bouw drone"
			          if !(player.larvae.empty? == true)
  						    player.larvae.first.train_unit(UnitTypes::Drone)
  						  end
  						  
  						end
					    #als de buildorder supply is bereikt en voldoende minerals, bouw gebouw
					    if (player.supply_used == buildOrderList.first.supply && player.minerals	>= buildOrder.cost)
                puts"buildStructure"
                issuedOrders.push(buildStructure(center.x,center.y,4,4,buildOrderList.first.u,buildOrderList.first.v,@@rc))
                puts"buildStructure complete"
                puts"issuedOrders.last.cost: #{issuedOrders.last.cost}, issuedOrders.last.workerId: #{issuedOrders.last.workerId}"
                spentMinerals = spentMinerals + issuedOrders.last.cost
                puts"#buildOrderList: #{buildOrderList.length}, supply: #{buildOrderList.first.supply}, shifting"
                buildOrderList.shift
                puts"buildOrderList.shift complete"
              end
					        
					    #presentWorkers = player.workers
					    
					    puts"#{issuedOrders.length}"
					    issuedOrders.each do |order|
					      if (order.type == player.units[order.workerId].type)
					        puts"done"
					        puts"spentminerals #{spentMinerals}"
					        spentMinerals = spentMinerals - order.cost
					        puts"spentminerals #{spentMinerals} na deductie"
					        issuedOrders.delete_if{|x| x.workerId == order.workerId}
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
      		  end
    			end
				
  				while(player.race == "Protoss")
  					if(last_frame	== starcraft.frame)
  						sleep(0.01)
  					else
  						last_frame = starcraft.frame
  
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
					end
				end
			end
		end
	end
end
