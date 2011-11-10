require "state_flow/version"

class StateFlow

  class InvalidStateError < StandardError ; end

  module DSL
    def state(name, &block)
      @states ||= []
      @states << State.new(name, &block)
    end
  end
  extend DSL

  def self.initial_state
    @states.find(&:initial?)
  end

  def self.find_state(name)
    @states.find { |s| s.name == name }
  end

  def self.states
    @states
  end

  class BlockValidator
    def initialize(block)
      @block = block
    end
    def validate(object)
      object.send(:instance_eval, &@block)
    end
  end

  class FieldValidator
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

  class Requirement
    attr_reader :message, :validator
    def initialize(message, *fields, &block)
      if fields.last.respond_to?(:validate)
        @validator = fields.pop
      elsif block_given?
        @validator = BlockValidator.new(block)
      else
        @validator = FieldValidator.new(*fields)
      end
      @message = message
      @fields = fields
    end

    def validate(object)
      @validator.validate(object)
    end
  end

  class State

    attr_reader :name, :source_states, :requirements
    def initialize(name, &block)
      @name = name
      @requirements = []
      @source_states = []
      instance_eval(&block) if block_given?
      validate_state_configuration!
    end

    def requirements_met?(object)
      requirements.all? { |req| req.validate(object) }
    end

    def from(*states)
      @source_states += states
    end

    def initial_state
      @initial = true
    end

    def initial?
      !! @initial
    end

    def requires(message, *fields, &block)
      @requirements << Requirement.new(message, *fields, &block)
    end

    private

    def validate_state_configuration!
      if !initial? && @source_states.size.zero?
        raise InvalidStateError, "Cannot have a non-initial state with no source transition states"
      end
    end

  end
end
