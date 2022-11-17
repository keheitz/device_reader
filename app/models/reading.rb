# frozen_string_literal: true

class Reading
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :timestamp, :count

  validates_presence_of :timestamp, :count
  validates :count, numericality: { only_integer: true }
  validates_with TimestampValidator

  def initialize(timestamp, count)
    @timestamp = timestamp
    @count = count
  end
end
