module AI
  class StateUnit
    include RProxyBot
    include RProxyBot::Constants::Orders
    include RProxyBot::Constants::UnitTypes
    include ConditionSyntax

    attr_accessor :unit
    attr_accessor :issued_orders
    attr_accessor :player

    def initialize(unit, player)
      self.unit = unit
      self.issued_orders = []
      self.player = player
    end

    def spawn(unit_type)
      issue_order(Order.new(
        lambda {
          unit.train_unit(unit_type)
        },
        condition {
          unit.type == unit_type
        },
        condition {
          type == Egg || type == unit_type
        }, OpenStruct.new({:minerals => Unit.mineral_cost(unit_type),
                          :gas => Unit.gas_cost(unit_type),
                          :supply => Unit.supply_required(unit_type)})
      ))
    end

    def mine(mineral_camp)
      issue_order(Order.new(
        lambda {
          unit.right_click_unit(mineral_camp)
        }
      ))
    end

    def build(building, location)
      issue_order(Order.new(
        lambda {
          unit.build(building, location[:x], location[:y])
        },
        condition {
          #unit is gebouw geworden
          unit.type == building
        },
        condition {
          #de unit is aan het bouwen of postcondition
          unit.is_morphing? || unit.type == building
        }, OpenStruct.new({:minerals => Unit.mineral_cost(building),
                          :gas => Unit.gas_cost(building),
                          :supply => Unit.supply_required(building)})
      ))
    end

    def idle?
      issued_orders.empty? && order == PlayerGuard
    end

    def issue_order(order)
      issued_orders << order
      order.execute
      player.process(order)
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
