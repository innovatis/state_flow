class StateFlow::RequirementsResult
  include Enumerable

  attr_reader :state_name
  attr_accessor :current
  def initialize(state_name, *pairs)
    @state_name = state_name
    @current = false
    @requirements = pairs
  end

  def requirements_met?
    @requirements.all? { |message, value| value }
  end

  def each(&block)
    @requirements.each(&block)
  end

  alias_method :current?, :current

end


