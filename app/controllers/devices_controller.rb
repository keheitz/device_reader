# frozen_string_literal: true

class DevicesController < ApplicationController
  def show
    @device = Device.new(params[:id])

    render json: { id: @device.id, last_reading: @device.last_reading, cumulative_count: @device.cumulative_count }
  end
end
