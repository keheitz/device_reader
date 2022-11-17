# frozen_string_literal: true

class ReadingsController < ApplicationController
  def create
    @device = Device.new(params[:id])
    @readings = []
    params[:readings].each do |r|
      @readings << Reading.new(r['timestamp'], r['count'])
    end
    # this might be more strict than we want...
    if @device.valid? && @readings.all?(&:valid?)
      @device.update_readings_cache(formatted_readings)
      render json: { id: @device.id, readings: @readings }, status: :created
    else
      render json: consolidated_errors, status: :bad_request
    end
  end

  private

  def formatted_readings
    @readings.map! { |r| { timestamp: r.timestamp, count: r.count } }
  end

  def consolidated_errors
    readings_errors = @readings.map { |r| r.errors.full_messages }.flatten
    { device: @device.errors.full_messages, readings: readings_errors }
  end
end
