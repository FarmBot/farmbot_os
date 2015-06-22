module FBPi
  class MeshMessage
    attr_accessor :from, :method, :params, :id

    def initialize(from:, method:, params: {}, id: '')
      @from, @method, @params, @id = from, method, params, id
    end
  end
end
