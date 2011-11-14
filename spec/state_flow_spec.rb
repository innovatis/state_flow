require './lib/state_flow'

describe StateFlow do

  describe "DSL and setup" do
    it 'can define an initial state' do
      klass = Class.new(StateFlow) {
        state :new do
          initial_state
        end
      }
      klass.initial_state.name.should == :new
      klass.states.size.should == 1
      klass.states[0].name.should == :new
    end

    it 'can define a state with source transition states' do
      klass = Class.new(StateFlow) {
        state :new do
          initial_state
        end
        state :closed do
          from :new
        end
      }
      klass.find_state(:closed).source_states.should == [:new]
    end

    it 'cannot define a non-initial state without a source transition state' do
      expect {
        klass = Class.new(StateFlow) {
          state :new do
            initial_state
          end
          state :closed do
          end
        }
      }.to raise_error(StateFlow::InvalidStateError)
    end

    it 'can define a state with a simple requirement' do
      klass = Class.new(StateFlow) {
        state :new do
          initial_state
        end
        state :closed do
          from :new
          requires "Thing", :thing
        end
      }
      klass.find_state(:closed).requirements[0].message.should == "Thing"
    end

    it 'can define a requirement with a validator class' do
      thing_validator = Class.new {
        def self.validate(*) ; end
      }
      klass = Class.new(StateFlow) {
        state :new do
          initial_state
        end
        state :closed do
          from :new
          requires "Thing", :thing, thing_validator
        end
      }
      klass.find_state(:closed).requirements[0].validator.should == thing_validator
    end

    it 'returns a validator class wrapper around blocks' do
      thing_validator = Class.new {
        def self.validate(*) ; end
      }
      klass = Class.new(StateFlow) {
        state :new do
          initial_state
        end
        state :closed do
          from :new
          requires "Thing", :thing do
            42
          end
        end
      }
      validator = klass.find_state(:closed).requirements[0].validator
      validator.should be_instance_of(StateFlow::BlockValidator)
    end

    it 'returns a defualt validator if only field names are given' do
      klass = Class.new(StateFlow) {
        state :new do
          initial_state
        end
        state :closed do
          from :new
          requires "Thing", :thing
        end
      }
      validator = klass.find_state(:closed).requirements[0].validator
      validator.should be_instance_of(StateFlow::FieldValidator)
    end

  end

  describe StateFlow::BlockValidator do
    it 'evaluates its block in the context of the object it is passed' do
      block = proc{ object_attribute }
      bv = StateFlow::BlockValidator.new(block)
      object = stub(:object_attribute => true)
      bv.validate(object).should be_true
    end
  end

  describe StateFlow::FieldValidator do
    it 'requires one field to be present on the object' do
      v = StateFlow::FieldValidator.new(:foo)
      tobject = stub(:foo => true)
      fobject = stub(:foo => false)
      v.validate(tobject).should be_true
      v.validate(fobject).should be_false
    end

    it 'requires an array of fields to be present' do
      v = StateFlow::FieldValidator.new(:foo, :bar)
      tobject = stub(:foo => true,  :bar => true)
      fobject = stub(:foo => true,  :bar => false)
      v.validate(tobject).should be_true
      v.validate(fobject).should be_false
    end

    it "accepts nested fields" do
      v = StateFlow::FieldValidator.new(:foo => :bar)
      object = stub(:foo => stub(:bar => true))
      v.validate(object).should be_true
    end
  end

  describe StateFlow::State do
    it 'knows whether its requirements are met' do
      state = StateFlow::State.new(:pending) do
        from :initial
        requires "Address", :address
        requires "City", :city
      end
      tobject = stub(:address => "123 Fake Street", :city => "Winnipeg")
      fobject = stub(:address => "123 Fake Street", :city => "")
      state.requirements_met?(tobject).should be_true
      state.requirements_met?(fobject).should be_false
    end
    it 'allows you to specify a weight to determine which state to go to when multiple are valid' do
      state = StateFlow::State.new(:void) do
        from :initial
        priority +1
        requires "voided", :voided
      end
      state.priority.should == 1
    end

    it 'generates a validation report' do
      state = StateFlow::State.new(:second) do
        from :initial
        requires "Thing A", :a
        requires "Thing B", :b
      end
      object = stub(:a => true, :b => false)
      state.requirements_result(object).should be_instance_of(StateFlow::RequirementsResult)
    end

    it 'knows whether it can be entered from another state' do
      frm = StateFlow::State.new(:initial) do
        initial_state
      end
      to = StateFlow::State.new(:second) do
        from :initial
      end
      to.enterable_from?(frm).should be_true
      frm.enterable_from?(to).should be_false
    end
  end

  describe StateFlow::RequirementsResult do
    it 'knows whether the whole state is valid' do
      rr = StateFlow::RequirementsResult.new(:pending, ['Thing A', true], ['Thing B', false])
      rr.requirements_met?.should be_false
    end

    it 'can be told it is was visited' do
      rr = StateFlow::RequirementsResult.new(:pending, ['Thing A', true], ['Thing B', false])
      rr.should_not be_visited
      rr.visited = true
      rr.should be_visited
    end

    it 'can be told it is the current state' do
      rr = StateFlow::RequirementsResult.new(:pending, ['Thing A', true], ['Thing B', false])
      rr.should_not be_current
      rr.current = true
      rr.should be_current
    end

    it "can iterate over its results" do
      rr = StateFlow::RequirementsResult.new(:pending, ['Thing A', true], ['Thing B', false])
      rr.map{|name, sat|name}.should == ['Thing A', 'Thing B']
    end

    it "knows the name of its state" do
      rr = StateFlow::RequirementsResult.new(:pending, [])
      rr.state_name.should == :pending
    end
  end

  describe StateFlow::FlowResult do
    let(:klass) {
      klass = Class.new(StateFlow) do
        state :a do
          initial_state
        end

        state :b do
          from :a
          requires "B", :b_requirement
        end

        state :c do
          from :b
          requires "C", :c_requirement
        end
      end
    }

    it 'determines what state an object is in' do
      aobject = stub(:b_requirement => false, :c_requirement => false)
      bobject = stub(:b_requirement => true, :c_requirement => false)
      cobject = stub(:b_requirement => true, :c_requirement => true)
      klass.flow(aobject).state.should == :a
      klass.flow(bobject).state.should == :b
      klass.flow(cobject).state.should == :c
    end

    it 'knows the path of states it took to get there' do
      object = stub(:b_requirement => true, :c_requirement => true)
      klass.flow(object).state_path.should == [:a, :b, :c]
    end

    it 'can look up the result for a state' do
      object = stub(:b_requirement => true, :c_requirement => true)
      klass.flow(object)[:b].visited?.should be_true
    end

    it 'knows whether a state was visited' do
      object = stub(:b_requirement => true, :c_requirement => true)
      klass.flow(object).visited?(:b).should be_true
    end

    it 'knows whether a state is current' do
      object = stub(:b_requirement => true, :c_requirement => true)
      klass.flow(object).current?(:c).should be_true
    end

    it 'can iterate over the states' do
      object = stub(:b_requirement => false, :c_requirement => false)
      klass.flow(object).map{|k,v|[v.current, k]}.
        should == [[true, :a], [false, :b], [false, :c]]
    end

  end

end
