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
