class JobRuleEngine < Rule::Engine::Base

  state :potential
  state :pending
  state :estimated
  state :scheduled
  state :in_progress
  state :completed
  state :closed
  state :lost
  state :cancelled
  state :overdue

  initial_state :potential

  terminal_state :lost
  terminal_state :cancelled
  terminal_state :closed

  [:potential, :pending, :estimated, :scheduled, :in_progress, :completed].each do |state|
    transition state, :lost do
      assert object.lost?, "Job must be marked lost"
      priority :high
    end
  end
  transition :lost, :potential do
    assert ! object.lost?, "Job must not be marked lost"
    priority :high
  end

  transition :closed, :lost do
    validate Rule::Disallow
  end

  transition :potential, :pending do
    validate Job::ClientInformationRequiredRule
    validate Job::IsCloseToWinnipegRule
  end

  transition :pending, :estimated do
    assert(object.estimated_at || object.estimate_not_required, "Estimate Date required")
  end

  transition :estimated, :scheduled do
    assert_presence_of object.booked_at, "Booking Date"
    assert_presence_of object.scheduled_for, "Scheduled For"
  end

  transition :scheduled, :completed do
    assert_presence_of object.completed_at, "Completion Date"
  end

  transition :scheduled, :in_progress do
    validate Job::IsInProgressRule
  end

  transition :in_progress, :scheduled do
    assert(object.scheduled_for && object.scheduled_for > Date.today, "Job must be scheduled later than today")
  end

  transition :in_progress, :completed do
    assert_presence_of object.completed_at, "Completion Date"
  end

  transition :completed, :closed do
    # validate Job::FullyPaidRule
    validate Rule::Disallow
  end

end
