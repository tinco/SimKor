module AI
  class State
    attr_accessor :starcraft
    attr_accessor :units

    def initialize(game)
      self.starcraft = game  
      self.units = {}
      update
    end

    def update
      starcraft.units.each do |unit|
        #make StateUnits for all units
        if not units.has_key? unit.id
          units[unit.id] = StateUnit.new(unit)
        end
      end
      #clean issued_orders
      units.each do |unit|
        unit.issued_orders.reject!(&:completed?)
      end
    end
  end # class State

  class StateUnit
    attr_accessor :unit
    attr_accessor :issued_orders

    def initialize(unit)
      self.unit = unit
      self.issued_orders = []
    end

    def spawn(unit_type)
      order do
        unit.train_unit(unit_type)
      end
    end

    def order(&order)
      issued_orders << order
      order.execute
    end

    #try to propagate method calls to the hidden unit
    def method_missing(name, *params)
      if unit.respond_to? name
        unit.send(name, *params)
      else
        super
      end
    end
  end

  class Order
    attr_accessor :postcondition
    attr_accessor :order

    def initialize(postcondition, &order)
      self.postcondition = postcondition
      self.order = order
    end

    def completed?
      postcondition.call
    end

    def execute
      order.call
    end

    #TODO: Order#failed?
  end
end # module AI
