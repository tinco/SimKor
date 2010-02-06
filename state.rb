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
          s_unit =  StateUnit.new(unit)
          units[unit.id] = s_unit
          players[unit.player_id].units[unit.id] = s_unit
        end
      end

      #clean issued_orders
      units.values.each do |unit|
        unit.issued_orders.reject!(&:completed?)
      end
    end
  end # class State

  class StatePlayer
    include RProxyBot::Constants::UnitTypes
    
    attr_accessor :player
    attr_reader :units

    def initialize(player)
      self.player = player
      @units = {}
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
    include RProxyBot::Constants::Orders
    attr_accessor :unit
    attr_accessor :issued_orders

    def initialize(unit)
      self.unit = unit
      self.issued_orders = []
    end

    def spawn(unit_type)
      issue_order(Order.new(
        Condition.new {
          unit.type == unit_type
        }, lambda {
          unit.train_unit(unit_type)
        }
      ))
    end

    def mine(mineral_camp)
      issue_order(Order.new(
        Condition.new {
          false #a unit mines indefinately
        }, lambda {
          unit.right_click_unit(mineral_camp)
        }
      ))
    end

    def idle?
      issued_orders.empty? && order == PlayerGuard
    end

    def issue_order(order)
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

    def initialize(postcondition, order)
      self.postcondition = postcondition
      self.order = order
    end

    def completed?
      postcondition.met?
    end

    def execute
      order.call
    end

    #TODO: Order#failed?
  end
end # module AI
