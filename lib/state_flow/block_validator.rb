class StateFlow::BlockValidator
  def initialize(block)
    @block = block
  end
  def validate(object)
    object.send(:instance_eval, &@block)
  end
end


