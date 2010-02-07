module AI
  module ConditionSyntax
    def condition(&block)
      Condition.new &block
    end

    alias :precondition :condition
    alias :postcondition :condition
  end

  #Conditions are procs that should return a boolean value
  class Condition < Proc
    def met?
      self.call
    end

    False = Condition.new {false}
    True = Condition.new {true}
  end #class Condition
end #module AI
