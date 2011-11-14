class StateFlow::FieldValidator
  EMPTY_THINGS = ["", [], {}]

  def initialize(*fields)
    @fields = fields
  end
  def validate(object)
    @fields.each do |field|
      return false unless presence(apply_field(object, field))
    end
    true
  end

  def presence(value)
    value && !EMPTY_THINGS.include?(value)
  end

  def apply_field(object, field)
    if field.kind_of?(Hash)
      key = field.keys.first
      apply_field(apply_field(object, key), field[key])
    else
      object.send(field)
    end
  end
end


