module AI
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
    attr_accessor :name, :postconditions, :preconditions, :order

    def initialize(name, &block)
      self.name = name
      self.postconditions = []
      self.preconditions = []
      instance_eval &block
    end

    def execute
      order.call
    end

    #A step has been satisfied if all its postconditions have been met
    def satisfied?
      postconditions.all?(&:met?)
    end

    #A step is ready to be executed if all its preconditions have been met
    def requirements_met?
      preconditions.all?(&:met?)
    end

    def precondition(&condition)
      preconditions << Condition.new(&condition)
    end

    def postcondition(&condition)
      postconditions << Condition.new(&condition)
    end

    def order(value = nil, &condition)
      @order = value || Condition.new(&condition)
    end
  end #class StrategyStep

  #strategy definition method:
  def strategy_step(name, &block)
    strategy_steps << StrategyStep.new(name, &block)
  end

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

  #build a unit
  def spawn(unit_type)
    player.larvae.first.spawn(unit_type)
  end

  #get a valid build location
  def build_location(building)
    #stom spiral algoritme ofzo
  end

  #get a build location for a building by spiraling out around a center location.
  def spiral_location(building, center)
    step_horizontal = 1 #building_width
    step_vertical = 1 #building height
    x = 0 ; y = 0 #center location
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
  end #spiral_location

  #check if a building can be placed on a site:
  def check_building(building, x, y)
    map.buildable? x.build_tiles, y.build_tiles
    #moet ook checken of het gebied egaal is
    #moet ook checken of er units op die tiles staan
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
