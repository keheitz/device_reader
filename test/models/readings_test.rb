require "test_helper"

class ReadingsTest < ActiveSupport::TestCase
    test "reading should be invalid if timestamp is not iso8601 format" do
        reading = Reading.new("blah", 3)
        assert reading.invalid?, "Reading valid with non-iso8601 timestamp"
    end

    test "reading should be invalid if count is not an integer" do
        reading = Reading.new(DateTime.now.iso8601, "not_an_integer")
        assert reading.invalid?, "Reading valid with non-integer count"
    end
end