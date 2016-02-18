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
      issue_order "Spawn #{unit_type.to_s}" do
        order do
          unit.train(unit_type)
        end

        postcondition do
          type == unit_type
        end

        failedcondition do
          type != UnitType.Zerg_Egg #hier moet iets slimmers voor komen...
        end

        startedcondition do
          type == UnitType.Zerg_Egg || type == unit_type #fancy method needed to DRY this up
        end

        cost({:minerals => unit_type.mineral_price,
              :gas => unit_type.gas_price,
              :supply => unit_type.supply_required})
      end
    end

    # override for overloaded java method
    def distance(other_unit)
      unit.java_send :getDistance, [Java::Bwapi::Unit], other_unit.unit
    end

    def right_click_unit(other_unit)
      unit.java_send :rightClick, [Java::Bwapi::Unit], other_unit.unit
    end
    
    def mine(mineral_camp)
      issue_order "Mine" do
        order do
          right_click_unit(mineral_camp)
        end
      end
    end

    def destroyed?
      dead?
    end

    def dead?
      exists? #TODO this does not cover it. It could also just be invisible
    end

    def attack(enemy)
      issue_order "Attack" do
        order do
          right_click_unit(enemy)
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
      issue_order "Build #{building}" do
        order do
          unit.build(building, TilePosition.new(location[:x], location[:y]))
        end

        postcondition do
          type == building
        end

        startedcondition do
          type == building || morphing? #fancy method needed to DRY this up
        end

        cost({:minerals => building.mineral_price,
              :gas => building.gas_price,
              :supply => building.supply_required})
      end
    end

    def idle?
      issued_orders.empty? && (
        if type == UnitType.Zerg_Drone
          order == Order.PlayerGuard
        else
          true
        end
      )
    end

    def issue_order(name, &block)
      issued_orders << order = StrategyOrder.new(self, name, &block)
      order.execute
      player.process(order)
      order
    end

    #try to propagate method calls to the hidden unit and its type
    def method_missing(name, *params)
      if unit.respond_to? name
        unit.send(name, *params)
      elsif unit.type.respond_to? name
        unit.type.send(name, *params)
      else
        super
      end
    end
  end #class StateUnit
end #module AI
