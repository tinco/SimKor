class Subscription
  #Basic events: de property van een unit veranderd, een unit word toegevoegd of verwijderd,
  #een unit wordt zichtbaar of onzichtbaar, de hoeveelheid resources verandert.
  #Complexe events: een unit komt in range van een andere unit, een mineral field is depleted,
  #een unit word aangevallen door een andere unit. Een unit in de buurt valt een unit aan.
  #een unit word gedetecteerd. Property verandert naar specifieke waarde of voldoet aan expressie.
  attr_accessor :subscriber, :property
  attr_accessor :name

  def trigger(unit, changes)
    subscriber.trigger(name, unit, changes)
  end

  def matches?(unit, changes)
    changes.properties.include? property
  end
end

class UnitSubscription < Subscription
  attr_accessor :unit

  def matches?(unit, changes)
    super && unit == self.unit
  end
end

class GroupSubscription < Subscription
  attr_accessor :group

  def matches?(unit, changes)
    super && group.include? unit
  end
end

class AreaSubscription < Subscription
  attr_accessor :area

  def matches?(unit, changes)
    super && area.contains?(unit)
  end
end

class GlobalSubscription < Subscription
end

class PlayerSubscription < Subscription
  attr_accessor :player

  def matches?(player, changes)
    super && player == self.player
  end
end

class EventMachine
  # Subscriptions
  attr_accessor :subscriptions

  def unit_updated(unit, changes)
    subscriptions.collect {|s|s.matches? unit, changes}.each do |subscription|
      subscription.trigger unit, changes
    end
  end
end
