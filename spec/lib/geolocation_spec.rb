require 'spec_helper'

describe Geolocation do
  before(:each) do
    @google_key = ENV['GOOGLE_PLACES_TOKEN']
    ENV['GOOGLE_PLACES_TOKEN'] = '7F8GI7AGI8G2IF723GF7832G'
  end
  after(:each) do
    ENV['GOOGLE_PLACES_TOKEN'] = @google_key
  end
  describe "find_places" do
    it "should query for matching places based on the specified location" do
      ENV['NEW_REGISTRATION_EMAIL'] = 'qwerty'
      obj = OpenStruct.new(:body => {
        'results' => []
      }.to_json)
      expect(Typhoeus).to receive(:get).with('https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=7F8GI7AGI8G2IF723GF7832G&location=0.0,0.0&radius=1000', {timeout: 5}).and_return(obj)
      expect(Geolocation.find_places(0, 0)).to eq([])
    end

    it "should query for matching places based on the specified location" do
      ENV['NEW_REGISTRATION_EMAIL'] = 'qwerty'
      obj1 = OpenStruct.new(:body => {
        'results' => [
          {'name' => 'asdf', 'geometry' => {'location' => {'lat' => 12, 'lng' => 12}}, 'types' => ['a', 'b']},
          {'name' => 'blech', 'geometry' => {'location' => {'lat' => 13, 'lng' => 13}}, 'types' => ['c', 'd']}
        ]
      }.to_json)
      expect(Typhoeus).to receive(:get).with('https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=7F8GI7AGI8G2IF723GF7832G&location=0.0,0.0&radius=1000', {timeout: 5}).and_return(obj1)
      res = Geolocation.find_places(0, 0)
      expect(res.length).to eq(2)
      expect(res).to eq([
        {'name' => 'asdf', 'latitude' => 12, 'longitude' => 12, 'image_url' => nil, 'types' => ['a', 'b']},
        {'name' => 'blech', 'latitude' => 13, 'longitude' => 13, 'image_url' => nil, 'types' => ['c', 'd']}
      ])
    end
  end
end
