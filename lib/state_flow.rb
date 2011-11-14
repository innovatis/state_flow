require "state_flow/version"
require 'state_flow/state'
require 'state_flow/requirements_result'
require 'state_flow/block_validator'
require 'state_flow/field_validator'
require 'state_flow/requirement'
require 'state_flow/flow_result'

class StateFlow

  class InvalidStateError < StandardError ; end

  def self.state(name, &block)
    @states ||= []
    @states << StateFlow::State.new(name, &block)
  end

  def self.initial_state
    @states.find(&:initial?)
  end

  def self.find_state(name)
    @states.find { |s| s.name == name }
  end

  def self.states
    @states
  end

  def self.flow(object)
    StateFlow::FlowResult.new(self, object)
  end

end

