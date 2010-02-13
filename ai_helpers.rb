module AI
  module AIHelpers
    include RProxyBot
    include RProxyBot::Constants
    include RProxyBot::Constants::UnitTypes
    #strategy definition method:
    def strategy_step(name, &block)
      strategy_steps << StrategyStep.new(name, self, &block)
    end

    #build a unit
    def spawn(unit_type)
      player.larvae.first.spawn(unit_type)
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

    #make the methods of the state available here
    def method_missing(name, *params)
      if state.respond_to? name
        state.send name, *params
      else
        super
      end
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

  class IssuedOrder
    #IssuedOrder contains information about buildorders that have
    #been issued but have not been completed

    attr_accessor :workerId
    attr_accessor :cost
    attr_accessor :type

    def initialize(workerId, cost, type)
      @workerId = workerId
      @cost = cost
      @type = type
    end
  end

  class BuildOrder
    #contains the building to be build
    #and the supply needed
    attr_accessor :supply
    attr_accessor :building
    attr_accessor :cost
    attr_accessor :height
    attr_accessor :width

    def initialize(supply,building,cost,height,width)
      @supply = supply
      @building = building
      @cost = cost
      @height = height
      @width = width
    end
  end

  ##strategy steps:
  #A step in a strategy with its post and pre conditions
  class StrategyStep
    include AIHelpers
		include	RProxyBot::Constants
    include RProxyBot::Constants::UnitTypes

    attr_accessor :name, :postconditions, :preconditions, :order

    def initialize(name, env, &block)
      self.name = name
      self.postconditions = []
      self.preconditions = []
      @env = env
      instance_eval &block
    end

    def execute
      order.call
    end

    #A step has been satisfied if all its postconditions have been met
    def satisfied?
      postconditions.all? &:met?
    end

    #A step is ready to be executed if all its preconditions have been met
    def requirements_met?
      preconditions.all? &:met?
    end

    def precondition(&condition)
      preconditions << Condition.new(&condition)
    end

    def postcondition(&condition)
      postconditions << Condition.new(&condition)
    end

    def order(&block)
      if block
        @order = block
      else
        @order
      end
    end

    def method_missing(name, *args)
      @env.send name, *args
    end
  end #class StrategyStep

  class Order
    attr_accessor :postcondition
    attr_accessor :startedcondition
    attr_accessor :order
    attr_accessor :cost

    def initialize(order, postcondition = Condition::False, startedcondition = Condition::True, cost = nil)
      self.postcondition = postcondition
      self.order = order
      self.startedcondition = startedcondition
      self.cost = cost
    end

    def completed?
      postcondition.met?
    end

    def execute
      order.call
    end

    def has_cost?
      cost
    end

    def started?
      startedcondition.met?
    end

    def costs_substracted!
      @substracted = true
    end

    def costs_substracted?
      @substracted
    end

    #TODO: Order#failed?
  end #class Order

end #module AI

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
