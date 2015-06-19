module FBPi
  # The purpose of this command object is to ingest Sequence and Schedule
  # resources from the API and join them together into one array. This is
  # typically used for syncing schedules (See FBPi::SyncBot)
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
        .with_index { |id, inx| schedules[inx][:sequence] = find_sequence(id) }
      schedules
    end

  private
    def find_sequence(id)
      sequences.detect { |s| s[:_id] == id }
    end
  end
end
