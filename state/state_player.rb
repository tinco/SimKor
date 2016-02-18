module AI
  class StatePlayer
    include Bwapi

    attr_accessor :player
    attr_reader :units

    def initialize(player)
      self.player = player
      @units = {}
      @spent_minerals = 0
      @spent_supply = 0
      @spent_gas = 0
      @supply_gained
    end

    def update
      units.values.each do |unit|
        unit.issued_orders.each do |order|
          if order.has_cost?
            if !order.costs_substracted? && order.started?
              @spent_minerals -= order.cost.minerals
              @spent_gas -= order.cost.gas
              @spent_supply -= order.cost.supply
              order.costs_substracted!
            end
          end
        end
      end
    end

    def process(order)
      if order.has_cost?
        @spent_minerals += order.cost.minerals
        @spent_supply += order.cost.supply
        @spent_gas += order.cost.gas
      end
    end

    def minerals
      player.minerals - @spent_minerals
    end

    def supply_used
      player.supply_used - @spent_supply
    end

    def supply_total
      (units.values.select {|u|u.type == UnitType.Zerg_Hatchery || u.type == UnitType.Zerg_Lair || u.type == UnitType.Zerg_Hive}.count * 2) +
      (units.values.select {|u|u.type == UnitType.Zerg_Overlord}.count * 16)
    end

    def supply_left
      supply_total - supply_used
    end

    def gas
      player.gas - @spent_gas
    end

    def command_centers
      units.values.select do |unit|
        unit.resource_depot?
      end
    end

    def workers
      units.values.select do |unit|
        unit.worker?
      end
    end

    def larvae
      units.values.select do |unit|
        unit.type == UnitType.Zerg_Larva
      end
    end	

    def available_larva
      larvae.select(&:idle?).first
    end

    def larva_available?
      larvae.any?(&:idle?)
    end

    def get_all_by_unit_type(unittype)
      units.values.select do |unit|
        unit.type == unittype
      end
    end

    def overlords
      units.values.select do |unit|
        unit.type == UnitType.Zerg_Overlord
      end
    end

    def eggs
      units.values.select do |unit|
        unit.type == UnitType.Zerg_Egg
      end
    end

    #propagate method calls to hidden player
    def method_missing(name, *params)
      if player.respond_to? name
        player.send(name, *params)
      else
        super
      end
    end
  end #class StatePlayer
end #module AI
