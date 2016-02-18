module AI
  class StateUnit
    include Bwapi

    attr_accessor :unit
    attr_accessor :issued_orders
    attr_accessor :player

    def initialize(unit, player)
      self.unit = unit
      self.issued_orders = []
      self.player = player
    end

    def spawn(unit_type)
      issue_order "Spawn #{Unit.name(unit_type)}" do
        order do
          unit.train_unit(unit_type)
        end

        postcondition do
          type == unit_type
        end

        failedcondition do
          type != UnitType.Egg #hier moet iets slimmers voor komen...
        end

        startedcondition do
          type == UnitType.Egg || type == unit_type #fancy method needed to DRY this up
        end

        cost({:minerals => Unit.mineral_cost(unit_type),
              :gas => Unit.gas_cost(unit_type),
              :supply => Unit.supply_required(unit_type)})
      end
    end

    def mine(mineral_camp)
      issue_order "Mine" do
        order do
          unit.right_click_unit(mineral_camp)
        end
      end
    end

    def destroyed?
      dead?
    end

    def attack(enemy)
      issue_order "Attack" do
        order do
          unit.right_click_unit(enemy)
        end

        postcondition do
          enemy.dead?
        end

        failedcondition do
          unit.order == PlayerGuard
        end
      end
    end

    def build(building, location)
      issue_order "Build #{Unit.name(building)}" do
        order do
          unit.build(building, location[:x], location[:y])
        end

        postcondition do
          type == building
        end

        startedcondition do
          type == building || is_morphing? #fancy method needed to DRY this up
        end

        cost({:minerals => Unit.mineral_cost(building),
              :gas => Unit.gas_cost(building),
              :supply => Unit.supply_required(building)})
      end
    end

    def idle?
      issued_orders.empty? && (
        if type == UnitType.Drone
          order == Order.PlayerGuard
        else
          true
        end
      )
    end

    def issue_order(name, &block)
      issued_orders << order = Order.new(self, name, &block)
      order.execute
      player.process(order)
      order
    end

    #try to propagate method calls to the hidden unit
    def method_missing(name, *params)
      if unit.respond_to? name
        unit.send(name, *params)
      else
        super
      end
    end
  end #class StateUnit
end #module AI
