class FakeRestClient
  def schedules
    @schedules ||= FakeSchedules.new
  end

  def sequences
    @sequences ||= FakeSequences.new
  end

  def plants
    @plants ||= FakePlants.new
  end

  class FakeSchedules
    def fetch
      [{"_id"=>"55819410766f6c5c93000000",
      "start_time"=>"2015-06-17T23:00:00.000Z",
      "end_time"=>"2015-06-30T23:00:00.000Z",
      "repeat"=>"12",
      "time_unit"=>"hourly",
      "sequence_id"=>"55310c9f70726f2d1c050000"}]
    end
  end

  class FakeSequences
    def fetch
      [{"_id"=>"55310c9f70726f2d1c050000",
      "name"=>"FARMBOT II: A New Hope",
      "steps"=>
      [{"command"=>{"x"=>"1100"}, "_id"=>"5531202a70726f2d1c140000", "message_type"=>"move_relative", "position"=>"0"},
      {"command"=>{"x"=>"-600"}, "_id"=>"5531202a70726f2d1c150000", "message_type"=>"move_relative", "position"=>"1"},
      {"command"=>{"x"=>"500"}, "_id"=>"55314a9d70726f0dd5000000", "message_type"=>"move_relative", "position"=>"2"}]},
      {"_id"=>"556f1037766f6c4d34000000", "name"=>"Untitled Sequence", "steps"=>[]},
      {"_id"=>"556f1037766f6c4d34010000", "name"=>"Untitled Sequence", "steps"=>[]},
      {"_id"=>"556f1038766f6c4d34020000", "name"=>"Untitled Sequence", "steps"=>[]}]
    end
  end

  class FakePlants
    def fetch
      [
        {
          "_id" => "561561cf766f6c6637000000",
          "device_id" => "56154f2f766f6c5789010000",
          "planting_area_id" => nil,
          "x" => 126,
          "y" => 193
         },{
          "_id" => "561561d1766f6c6637010000",
          "device_id" => "56154f2f766f6c5789010000",
          "planting_area_id" => nil,
          "x" => 245,
          "y" => 127
        }
      ]
    end
  end
end
