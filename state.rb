module AI
  class State
    attr_accessor :starcraft
    attr_accessor :units
    attr_accessor :player
    attr_accessor :players

    def initialize(game)
      self.starcraft = game  
      self.units = {}
      self.players = {}

      #make StatePlayers for all players
      starcraft.players.each do |player|
        players[player.id] = StatePlayer.new(player)
      end

      #the player itself
      self.player = players[starcraft.player.id]

      update
    end

    def update
      starcraft.units.each do |unit|
        #make StateUnits for all units
        if not units.has_key? unit.id
          s_unit =  StateUnit.new(unit,players[unit.player_id])
          units[unit.id] = s_unit
          players[unit.player_id].units[unit.id] = s_unit
        end
      end

      player.update

      #clean issued_orders
      units.values.each do |unit|
        unit.issued_orders.reject!(&:completed?)
      end
    end #method update
  end # class State

  class StatePlayer
    include RProxyBot::Constants::UnitTypes
    
    attr_accessor :player
    attr_reader :units

    def initialize(player)
      self.player = player
      @units = {}
      @spent_minerals = 0
      @spent_supply = 0
      @spent_gas = 0
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

    def supply_left
      player.supply_total - supply_used
    end

    def gas
      player.gas - @spent_gas
    end

    def command_centers
      units.values.select do |unit|
        unit.is_resource_depot?
      end
    end

    def workers
      units.values.select do |unit|
        unit.is_worker?
      end
    end

    def larvae
      units.values.select do |unit|
        unit.type == Larva
      end
    end	

    def get_all_by_unit_type(unittype)
      units.values.select do |unit|
        unit.type == unittype
      end
    end

    def overlords
      units.values.select do |unit|
        unit.type == Overlord
      end
    end

    def eggs
      units.values.select do |unit|
        unit.type == Egg
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
  end

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
          unit.type == Egg || unit.type == unit_type
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
          #unit...
        },
        condition {
          #unit is weg en er bestaat een gebouw
        },
        condition {
          #de unit is aan het bouwen of postcondition
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
  end

end # module AI
