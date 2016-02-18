module AI
  module Helpers
    include Bwapi

    #strategy definition method:
    def strategy_step(name, &block)
      strategy_steps.merge!({name => StrategyStep.new(name, self, &block)})
    end

    #build a unit
    def spawn(unit_type)
      if (larva = player.available_larva)
        larva.spawn(unit_type)
      end
    end

    def attack_nearest_enemy(unit)
      #attack units first!
      if((enemies = enemy.units.values.reject(&:is_building?).reject(&:dead?).reject(&:is_worker?).reject(&:is_flyer?)).any? ||
       (enemies = enemy.units.values.reject(&:is_building?).reject(&:dead?).reject(&:is_flyer?)).any? ||
       (enemies = enemy.units.values.reject(&:destroyed?)).any?) ||
       (enemies = state.starcraft.units.select(&:is_refinery?))
        enemy = enemies.sort_by {|e| unit.distance_to(e)}.first
      end
      unit.attack enemy if enemy
    end

    #get a valid build location
    def build_location(building)
      #stom spiral algoritme ofzo
      center = player.command_centers.first
      #spiral_location(building, {:x => center.tile_position_x,
      #               :y => center.tile_position_y})
      {:x => center.x.in_build_tiles, :y => center.y.in_build_tiles - 3}
    end

    #get a build location for a building by spiraling out around a center location.
    def spiral_location(building, center)
      step_horizontal = 1
      step_vertical = 1
      #ook nog een spiral_increment nodig?
      x = center[:x] ; y = center[:y] #center location
      check = lambda { check_building(building, x, y) }
      found = false
      spiral_width = 1
      while(not found) #binnen de map!
        spiral_width.times do 
          x += step_vertical
          break if found = check.call
        end
        break if found
        spiral_width.times do
          y -= step_horizontal
          break if found = check.call
        end
        break if found
        spiral_width += 1

        spiral_width.times do
          x -= step_vertical
          break if found = check.call
        end
        break if found
        spiral_width.times do
          y += step_horizontal
          break if found = check.call
        end
        spiral_width += 1
      end
      found ? {:x => x, :y => y} : nil
    end #spiral_location

    #check if a building can be placed on a site:
    def check_building(building, x, y)
      (0..Unit.tile_width(building) - 1).each do |dx|
        (0..Unit.tile_height(building) -1).each do |dy|
          map.buildable? x + dx, y + dy
        end
      end
      #TODO moet ook checken of de positie binnen restricted coords valt.
      #TODO moet ook checken of het gebied egaal is
      #TODO moet ook checken of er units op die tiles staan
    end
  end #module AIHelpers

  class Coordinate
    #Class for creating coordinate objects. An object contains an x and y value.

    attr_accessor :x
    attr_accessor :y

    def initialize(x,y)
      @x = x
      @y = y

    end

    #rewriting of eql? and hash required in order to compare the coordinate objects
    def eql?(arg)
      self.hash == arg.hash
    end

    def hash
      "x#{@x}y#{@y}".hash
    end

    def to_s
      "#{@x},#{@y}"
    end
  end
end #module AI

def proc_bind(env, &block) 
  Proc.new { env.instance_eval(&block) } #TODO: when arguments are necessary replace with instance_exec
end

class Fixnum
  def build_tiles
    self * 32
  end

  def in_build_tiles
    self / 32
  end

  def walk_tiles
    self * 8
  end

  def in_walk_tiles
    self / 8
  end

  alias :b_tiles :build_tiles
  alias :w_tiles :walk_tiles
end
