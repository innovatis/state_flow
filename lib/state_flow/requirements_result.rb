class StateFlow::RequirementsResult
  include Enumerable

  attr_reader :state_name
  attr_accessor :current, :visited
  def initialize(state_name, *pairs)
    @state_name = state_name
    @current = false
    @visited = false
    @requirements = pairs
  end

  def requirements_met?
    @requirements.all? { |message, value| value }
  end

  def each(&block)
    @requirements.each(&block)
  end

  alias_method :current?, :current
  alias_method :visited?, :visited

end


