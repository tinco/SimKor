class Behavior
  def self.on_event(name, &block)
    reactions[name] = block
  end

  def self.reactions
    @reactions ||= {}
  end

  attr_accessor :unit

  def trigger(event_name)
    instance_eval &(self.class.reactions[event_name])
  end
end

class MoveBehavior < Behavior
  on_event :reached_destination do
    unit.hold
  end
end

class Unit
  def hold
    puts "holding"
  end
end

zergling = Unit.new
behavior = MoveBehavior.new
behavior.unit = zergling
behavior.trigger :reached_destination

# holding
