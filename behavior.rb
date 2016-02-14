class Behavior
  def self.on_event(name, &block)
    define_method(name, &block)
  end

  attr_accessor :unit
end

class MoveBehavior < Behavior
  on_event :reached_destination do
    unit.hold
  end

  on_event :seen_treasure do |position|
    unit.move(position)
  end
end

module Behaves
  attr_accessor :behavior

  def trigger(event_name, *params)
    behavior.send(event_name, *params)
  end

  def exert(behavior, *params)
    self.behavior = behavior.new(*params)
    self.behavior.unit = self
  end
end

class Unit
  include Behaves

  def hold
    puts "holding"
  end

  def move(pos)
    puts "moving: #{pos}"
  end
end

#een unit krijgt een missie, Scout, Guard, Miner, Attacker
#een unit met een missie kan tasks toegewezen krijgen: ScoutThere, GuardHere, AttackThere, ExpandHere
#een unit met een behavior mag zijn eigen tijd besteden voor dingen binnen zijn behavior.
#
#Voorbeeld:
#scout:
#Task 1: ScoutHere, ScoutThere, ScoutEveryWhere
#

zergling = Unit.new
zergling.exert(MoveBehavior)
zergling.trigger :reached_destination
zergling.trigger :seen_treasure, 5

# holding

class RendezvousBehavior
  include Behavior

  mission "rendezvous at location", :with => [:location]

  events {
    :arrival => [ReachedLocation, :unit, :location],
    :in_attack_range => [InAttackRange, :unit],
    :unreachable => [OrderCancelled, :unit],
    :enemy_in_range => [EnemyInRange, :unit]
  }

  def arrival
    @unit.halt
  end

  def in_attack_range(enemy)
    @unit.reroute
  end

  def unreachable
    @unit.wait_for_further_orders
  end

  def enemy_in_range(enemy)
    @unit.attack_while_moving(enemy)
  end

  def initialize(location)
    @location = location
  end
end
