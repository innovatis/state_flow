class StateFlow::State

  attr_reader :name, :source_states, :requirements, :priority
  def initialize(name, &block)
    @name = name
    @requirements = []
    @source_states = []
    @priority = 0
    instance_eval(&block) if block_given?
    validate_state_configuration!
  end

  def requirements_result(object)
    result = @requirements.map do |req|
      [req.message, req.validate(object)]
    end
    StateFlow::RequirementsResult.new(name, *result)
  end

  def priority(priority = nil)
    if priority
      @priority += priority
    else # getter
      return @priority
    end
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

  def enterable_from?(state)
    @source_states.include?(state.name)
  end

  def initial?
    !! @initial
  end

  def requires(message, *fields, &block)
    @requirements << StateFlow::Requirement.new(message, *fields, &block)
  end

  private

  def validate_state_configuration!
    if !initial? && @source_states.size.zero?
      raise StateFlow::InvalidStateError, "Cannot have a non-initial state with no source transition states"
    end
  end

end

