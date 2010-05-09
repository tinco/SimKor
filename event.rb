class EventMachine
  def property_changed(property, oldvalue, newvalue)
  end

  attr_accessor :subscriptions
end

class Subscription
  #Basic events: de property van een unit veranderd, een unit word toegevoegd of verwijderd,
  #een unit wordt zichtbaar of onzichtbaar, de hoeveelheid resources verandert.
  #Complexe events: een unit komt in range van een andere unit, een mineral field is depleted,
  #een unit word aangevallen door een andere unit. Een unit in de buurt valt een unit aan.
  #een unit word gedetecteerd. Property verandert naar specifieke waarde of voldoet aan expressie.
  attr_accessor :subscriber
end

class PropertyChangedSubscription
  attr_accessor :unit, :property
end

class GlobalPropertyChangedSubscription
  attr_accessor :property
end

class PlayerPropertySubscription
  attr_accessor :player, :property
end
