require 'active_support/ordered_hash'

class StateFlow::FlowResult
  include Enumerable

  def initialize(flow, object)
    @flow = flow
    @object = object
    @state_info = calculate_state_info
    @state_info[state_object].current = true
  end

  def state
    state_object.name
  end

  def state_object
    @state_object ||= next_state_from(@flow.initial_state)
  end

  def each(&block)
    @state_info.each(&block)
  end

  private

  def next_state_from(state)
    if nxt = valid_states_from(state).sort_by(&:priority).first
      next_state_from(nxt)
    else
      state
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
