class NormalizeEmailEventTypes < ActiveRecord::Migration[8.0]
  def up
    execute("UPDATE email_events SET event_type = 'opened'  WHERE event_type = 'open'")
    execute("UPDATE email_events SET event_type = 'clicked' WHERE event_type = 'click'")
  end

  def down
  end
end
