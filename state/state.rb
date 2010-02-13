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

    def map
      starcraft.map
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
end
