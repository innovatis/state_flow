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
  end

end
