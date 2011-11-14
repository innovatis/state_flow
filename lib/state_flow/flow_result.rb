require 'active_support/ordered_hash'

class StateFlow::FlowResult
  include Enumerable

  def initialize(flow, object)
    @flow = flow
    @object = object
    @state_info = calculate_state_info
    state_path_objects.each do |state|
      @state_info[state].visited = true
    end
    @state_info[state_object].current = true
  end

  def state
    state_object.name
  end

  def state_object
    @state_object ||= state_path_objects.last
  end

  def each(&block)
    publicized_state_info.each(&block)
  end

  def state_path
    state_path_objects.map(&:name)
  end

  private

  def publicized_state_info
    @state_info.inject({}) do |acc, (state, result)|
      acc[state.name] = result
      acc
    end
  end

  def state_path_objects(visited = [@flow.initial_state])
    return @state_path if @state_path
    if nxt = valid_states_from(visited.last).sort_by(&:priority).first
      state_path_objects(visited + [nxt])
    else
      @state_path = visited
    end
  end

  def valid_states_from(state)
    possible_states_from(state).
      select { |s| @state_info[s].requirements_met? }
  end

  def possible_states_from(state)
    @flow.states.select { |s| s.enterable_from?(state) }
  end

  def calculate_state_info
    ah = ActiveSupport::OrderedHash.new
    @flow.states.inject(ah) do |info, state|
      info[state] = state.requirements_result(@object)
      info
    end
  end

end
