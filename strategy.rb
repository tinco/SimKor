module AI
  ##strategy steps:
  #A step in a strategy with its post and pre conditions
  class StrategyStep
    include AIHelpers
		include	RProxyBot::Constants
    include RProxyBot::Constants::UnitTypes

    attr_accessor :name, :postconditions, :preconditions, :order

    def initialize(name, env, &block)
      self.name = name
      self.postconditions = []
      self.preconditions = []
      @env = env
      instance_eval &block
    end

    def execute
      order.call
    end

    #A step has been satisfied if all its postconditions have been met
    def satisfied?
      postconditions.all? &:met?
    end

    #A step is ready to be executed if all its preconditions have been met
    def requirements_met?
      preconditions.all? &:met?
    end

    def precondition(&condition)
      preconditions << Condition.new(&condition)
    end

    def postcondition(&condition)
      postconditions << Condition.new(&condition)
    end

    def order(&block)
      if block
        @order = block
      else
        @order
      end
    end

    def method_missing(name, *args)
      @env.send name, *args
    end
  end #class StrategyStep

  class Order
    attr_accessor :postcondition
    attr_accessor :startedcondition
    attr_accessor :order
    attr_accessor :cost

    def initialize(order, postcondition = Condition::False, startedcondition = Condition::True, cost = nil)
      self.postcondition = postcondition
      self.order = order
      self.startedcondition = startedcondition
      self.cost = cost
    end

    def completed?
      postcondition.met?
    end

    def execute
      order.call
    end

    def has_cost?
      cost
    end

    def started?
      startedcondition.met?
    end

    def costs_substracted!
      @substracted = true
    end

    def costs_substracted?
      @substracted
    end

    #TODO: Order#failed?
  end #class Order
end #module AI
