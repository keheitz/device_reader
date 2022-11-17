# frozen_string_literal: true

class TimestampValidator < ActiveModel::Validator
  def validate(record)
    Time.iso8601(record.timestamp)
  rescue ArgumentError => e
    record.errors.add :base, 'Provided timestamp value is not iso8601 format'
  end
end
