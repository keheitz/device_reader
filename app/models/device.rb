# frozen_string_literal: true

class Device
  include ActiveModel::Model

  attr_accessor :id

  validates :id, presence: true

  def initialize(id)
    @id = id
  end

  def cumulative_count
    readings.sum { |r| r[:count] }
  end

  def last_reading
    readings.sort_by { |r| r[:timestamp] }.last
  end

  def update_readings_cache(posted_readings)
    # if we receive readings we already have, drop duplicates
    # assuming we won't have a case with same timestamp and different count 
    # for given device
    merged_values = (readings + posted_readings).uniq
    Rails.cache.write(@id, merged_values)
  end

  private

  def readings
    Rails.cache.fetch(@id) do
      []
    end
  end
end
