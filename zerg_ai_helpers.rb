module AI
  module ZergAIHelpers
    include RProxyBot
    include RProxyBot::Constants
    #this method provides an array of mineralspots that are 
    #within a 9 unit radius of the command center
    def initial_mineral_spots
      starcraft.units.minerals.select do |u|
        u.distance_to(player.command_centers.first) < 9.build_tiles
      end
    end

    def initial_vespene_geysers
      starcraft.units.vespene_geysers.select do |u|
        u.distance_to(player.command_centers.first) < 9.build_tiles
      end
    end

    #returns array of tile-coordinates of specified building
    #building location (x,y), size height*width
    def building_coordinates(x, y, height, width)
      puts"building #{height}x#{width} at location (#{x},#{y})"
      coords = Array.new
      (0..width-1).each do |j|

        (0..height-1).each do |i|

          co = Coordinate.new(x+i.build_tiles,y+j.build_tiles)
          coords.push(co)
        end

      end
      puts"*getBuildingCoordinates* returning array of building coordinates"
      coords
    end


    def check_site(x,y, height, width)
      #checks if the  target building can be built on tile (x,y), using restricted tileset rc
      #building has size height*width
      #puts"checking Site"
      buildable = true
      coords = Array.new
      freetiles = Array.new
      (0..width-1).each do |j|

        (0..height-1).each do |i|

          co = Coordinate.new(x+i.build_tiles,y+j.build_tiles)
          coords.push(co)
        end
      end

      #subtract the restricted coords array from the building_site_coordinates array
      #puts"freetiles = coords - rc"
      freetiles = coords - @rc
      #puts"freetiles = coords - rc DONE"

      #site is only buildable if all tiles are buildable
      if (freetiles.length < height+width)
        buildable = false
      end

      buildable
    end

    def make_coord_array(x,y,resource_x,resource_y, height, width)
      puts"makeCoordArray called"
      coords = Array.new
      #(x,y) are CC coords, (a,b) are resource (mineral/geyser) coords
      #u*v are dimensions of the tiles
      #providing a coordinate and another coordinate/rester, this method provides an array of coordinates
      #that fall within the coordinate and raster

      ([y, resource_y].min.in_build_tiles..[y,(resource_y+width.b_tiles)].max.in_build_tiles).each do |j|

        ([x,resource_x].min.in_build_tiles..[x,(resource_x+height.b_tiles)].max.in_build_tiles).each do |i|

          #create a coordinate with the x and y values, push on array
          co = Coordinate.new(i.build_tiles,j.build_tiles)
          coords.push(co)
        end        

      end

      coords  

    end


    def restricted_coords
      #retrieve array of mineralspots close to CC
      mineralspots = initial_mineral_spots
      vespenespots = initial_vespene_geysers

      #array of coords of geyser (1 geyser at the moment!)
      vespenecoords = Array.new
      vespenecoords = building_coordinates(vespenespots.last.x,vespenespots.last.y,4,2)
      puts "Vespenecoords.length #{vespenecoords.length}"

      #create an array that will contrain all restricted coordinates
      rescoords = Array.new
      #for every mineralspot, and array of restricted coordinates retrieved
      done = false
      while (not done)
        rescoords.concat(make_coord_array(player.command_centers.first.x, 
                                          player.command_centers.first.y,
                                          mineralspots.last.x,
                                          mineralspots.last.y, 2,1))
        mineralspots.pop
        done = mineralspots.last.nil?
      end

      done = false

      while (not done)
        rescoords.concat(make_coord_array(player.command_centers.first.x,
                                          player.command_centers.first.y,
                                          vespenecoords.last.x,
                                          vespenecoords.last.y, 4, 2))
        vespenecoords.pop
        done = vespenecoords.last.nil?
      end
      puts"end of getRestrictedCoords, rescoords.length #{rescoords.length}"
      rescoords
    end

    def spiral_coords(x, y, height, width, distance)
      #provides an array of coordinates around 
      #the a*b tileset located at coordinate (x,y)
      #distance spiral<->tileset is n

      #calculate the starting position for the spiral
      xLoc = x - distance.build_tiles
      yLoc = y - distance.build_tiles

      #The size of the source building determines the size of the spiral
      rasterSizeX = (2*distance.b_tiles)+height.b_tiles-1
      rasterSizeY = (2*distance.b_tiles)+width.b_tiles-1
      kanBouwen = true
      tiles = Array.new

      #Top row of tiles        
      (0..(rasterSizeX.in_build_tiles)).each do |i|
        xCoordinaat = xLoc + i.build_tiles
        co = Coordinate.new(xCoordinaat,yLoc)
        tiles.push(co)
      end

      #Right row of tiles (excluding top right)          
      (1..(rasterSizeY.in_build_tiles)).each do |i|
        yCoordinaat = yLoc + i.build_tiles
        co = Coordinate.new(xLoc+rasterSizeX,yCoordinaat)
        tiles.push(co)
      end

      #Bottom row of tiles (excluding bottom right)  
      (0..(rasterSizeX-1).in_build_tiles).each do |i|
        xCoordinaat = xLoc + i.build_tiles
        co = Coordinate.new(xCoordinaat,yLoc+rasterSizeY)
        tiles.push(co)
      end

      #Left row of tiles (excluding bottom left and top left)
      (1..(rasterSizeY-1).in_build_tiles).each do |i|
        yCoordinaat = yLoc + i.build_tiles
        co = Coordinate.new(xLoc,yCoordinaat)
        tiles.push(co)
      end
      puts"*getSpiralCoords complete*"        
      puts"Tiles.length #{tiles.length}"
      tiles
    end

    def buildable_coords(x,y,height,width,target_height,target_width,rc)
      #returns all coordinates where the structure with size u*v
      #can be built around source building a*b at location (x,y)
      #bc are buildable coordinates
      bc = Array.new

      #n is iteratie nr. Voor gemak even hoogte van gebouw (zodat hij op horizontale rij geplaatst kan worden)
      n = target_width
      canBuild = false
      noMoreCoordsAvail = false
      #sc are spiral coordinates
      #First receive the spiral of coords around source building
      sc = Array.new
      sc = spiral_coords(x,y,height,width,n)
      while (noMoreCoordsAvail == false) #TODO dubbele ontkenning
        #For each coordinate in the spiral, check if the building can be placed
        #puts"entering checkSite"
        if(check_site(sc.last.x,sc.last.y,target_width,target_height))
          co = Coordinate.new(sc.last.x,sc.last.y)
          bc.push(co)
        end

        sc.pop
        noMoreCoordsAvail = sc.last.nil?

      end
      puts"*getBuildableCoords complete*"
      bc  

    end

    def build_structure(x, y, height, width, target_height, target_width, rc)
      #(x,y), source bld coords, size a*b
      #target building size u*v
      #rc are restricted coords between minerals and CC
      #returns an order object containing order info

      bc = Array.new
      bc = buildable_coords(x,y, height, width, target_height, target_width, rc)
      player.workers.first.build(UnitTypes::SpawningPool,	bc.last.x, bc.last.y)
      puts"voor brc"
      brc = building_coordinates(bc.last.x, bc.last.y, target_height, target_width) 
      puts"brc complete"
      @rc.concat(brc)
      puts"concat rc complete"
      @rc.uniq!
      puts"uniq rc complete"
      io = IssuedOrder.new(player.workers.first.id, Unit.mineral_cost(UnitTypes::SpawningPool), UnitTypes::SpawningPool)
      puts"#{io.workerId},#{io.cost}"
      io
    end
  end #module ZergAIHelpers
end #module AI
