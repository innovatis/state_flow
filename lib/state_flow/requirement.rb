class StateFlow::Requirement
  attr_reader :message, :validator
  def initialize(message, *fields, &block)
    if fields.last.respond_to?(:validate)
      @validator = fields.pop
    elsif block_given?
      @validator = StateFlow::BlockValidator.new(block)
    else
      @validator = StateFlow::FieldValidator.new(*fields)
    end
    @message = message
    @fields = fields
  end

  def validate(object)
    @validator.validate(object)
  end
end

