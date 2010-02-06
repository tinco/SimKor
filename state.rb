module AI
  class State
    attr_accessor :starcraft

    def initialize(game)
      self.starcraft = game  
    end
  end # class State

  class StateUnit < Unit
    attr_accessor :issued_orders

    def spawn(unit_type)
      order do
        train_unit(unit_type)
      end
    end

    def order(&order)
      issued_orders ||= []
      issued_orders << order
    end
  end

  class Order
    attr_accessor :postconditions
  end
end # module AI
