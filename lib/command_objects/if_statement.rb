module FBPi
  # Conditionally executes a sequence if `operator(lhs, rhs)` evals to true.
  # used in the execution of steps.
  class IfStatement < Mutations::Command
    required do
      string :lhs
      string :rhs
      string :operator, in: %w(> < != ==)
      model  :sequence
      duck   :bot
    end

    def execute
      sequence.exec(bot) if lhs.send(operator, rhs)
    end
  end
end
