module FBPi
  # an if_statement is one of the many `message_type`s that a step can have.
  # This command uses relevant information in an if statement to execute a
  # sequence, but only if the if statement evaluates to true, using the left
  # hand side, right hand side and a set of allowable operators (eg: <, >, !=..)
  # Used in the execution of steps.
  Conditionally executes a sequence if `operator(lhs, rhs)` evals to true.
  class IfStatement < Mutations::Command
    required do
      string :lhs
      string :rhs
      string :operator, in: %w(> < != ==)
      model  :sequence
      duck   :bot
    end

    def execute
      sequence.exec(bot) if evaluates_to_true
    end

private

    def evaluates_to_true
      lhs.send(operator, rhs)
    end
  end
end
