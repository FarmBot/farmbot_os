module FBPi
  # Was once called ScheduleFactory
  class JoinSequenceSchedules < Mutations::Command
    required do
      array :schedules do
        hash do
          required do
            string :_id
            string :start_time
            string :end_time
            string :repeat
            string :time_unit
            string :sequence_id
          end
        end
      end

      array :sequences do
        hash do
          required do
            string :_id
            string :name
            array :steps do
              hash do
                string :*
                hash :command do
                  string :*
                end
              end
            end
          end
        end
      end
    end

    def execute
      schedules
        .map { |s| s.delete(:sequence_id) }
        .map
        .with_index { |s, i| schedules[i][:sequence] = find_sequence(s) }
      schedules
    end

  private
    def find_sequence(_id)
      sequences.detect { |s| s[:_id] == "55310c9f70726f2d1c050000" }
    end
  end
end
