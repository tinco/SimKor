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

class Unit
  attr_accessor :behavior

  def trigger(event_name, *params)
    behavior.reactions[event_name].call(*params)
  end

  def exert(behavior, *params)
    self.behavior = behavior.new(*params)
    self.behavior.unit = self
  end

  def hold
    puts "holding"
  end
end

zergling = Unit.new
zergling.exert(MoveBehavior)
zergling.trigger :reached_destination

# holding
