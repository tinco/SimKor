module AI
  class Step
    def initialize(env, &block)
      @env = env
      instance_eval &block
    end

    def make_condition(&block)
      Condition.new(&(proc_bind(@env, &block)))
    end

    def make_proc(&block)
      proc_bind(@env, &block)
    end
  end
  ##strategy steps:
  #A step in a strategy with its post and pre conditions
  class StrategyStep < Step
    attr_accessor :name, :postconditions, :preconditions, :progressconditions, :order

    def initialize(name, env, &block)
      self.name = name
      self.postconditions = []
      self.preconditions = []
      self.progressconditions = []
      super env, &block
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

    #A step is in progress if any of its progressconditions are met
    def in_progress?
      progressconditions.any? &:met?
    end

    def precondition(name=nil, &condition)
      if name
        preconditions.merge @env.strategy_steps[name].postconditions
      else
        preconditions << make_condition(&condition)
      end
    end

    def postcondition(&condition)
      postconditions << make_condition(&condition)
    end

    def progresscondition(&condition)
      progressconditions << make_condition(&condition)
    end

    def order(&block)
      if block
        @order = make_proc(&block)
      else
        @order
      end
    end
  end #class StrategyStep

  class StrategyOrder < Step
    attr_accessor :postcondition
    attr_accessor :startedcondition
    attr_accessor :order
    attr_accessor :cost
    attr_accessor :name

    def initialize(env, name, &block)
      self.name = name
      super env, &block
    end

    def completed?
      if postcondition
        postcondition.met?
      else
        true
      end
    end

    def execute
      order.call
    end

    def has_cost?
      cost
    end

    def started?
      if startedcondition
        startedcondition.met?
      else
        true
      end
    end

    def has_failed?
      if failedcondition
        failedcondition.met?
      else
        false
      end
    end

    def postcondition(&block) #must this be DRY'ed up with started and order?
      if block
        @postcondition = make_condition(&block)
      else
        @postcondition
      end
    end

    def startedcondition(&block)
      if block
        @startedcondition = make_condition(&block)
      else
        @startedcondition
      end
    end

    def failedcondition(&block)
      if block
        @failedcondition = make_condition(&block)
      else
        @failedcondition
      end
    end

    def order(&block) #must this be DRY'ed up with started and post?
      if block
        @order = make_proc(&block)
      else
        @order
      end
    end

    def cost(hash=nil)
      if hash
        @cost = OpenStruct.new(hash)
      else
        @cost
      end
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
