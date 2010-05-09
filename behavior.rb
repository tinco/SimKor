class Behavior
  def self.on_event(name, &block)
    reactions[name] = block
  end

  def self.reactions
    @reactions ||= {}
  end

  attr_accessor :unit

  def reactions
    self.class.reactions
  end
end

class MoveBehavior < Behavior
  on_event :reached_destination do
    unit.hold
  end
end

module Behaves
  attr_accessor :behavior

  def trigger(event_name, *params)
    behavior.instance_eval(*params, &(behavior.reactions[event_name]))
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
end

#hoe triggeren we deze events?
#hoe krijgen units behaviours?
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

# holding
