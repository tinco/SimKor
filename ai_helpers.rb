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
    attr_accessor :u
    attr_accessor :v

    def initialize(supply,building,cost,u,v)
      @supply = supply
      @building = building
      @cost = cost
      @u = u
      @v = v
    end
  end
end
