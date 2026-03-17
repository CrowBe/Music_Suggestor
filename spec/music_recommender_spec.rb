# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe MusicRecommender do
  subject(:recommender) { described_class.new }

  describe "#ai_available?" do
    context "when ANTHROPIC_API_KEY is not set" do
      before { allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return(nil) }

      it "returns false" do
        expect(recommender.ai_available?).to be false
      end
    end

    context "when ANTHROPIC_API_KEY is the placeholder" do
      before { allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("your_api_key_here") }

      it "returns false" do
        expect(recommender.ai_available?).to be false
      end
    end
  end

  describe "#recommend" do
    context "with fallback data (no API key)" do
      before { allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return(nil) }

      it "returns a song for a valid mood" do
        song = recommender.recommend(category_type: :mood, category_name: "Rage")

        expect(song).to be_a(Hash)
        expect(song[:title]).to be_a(String)
        expect(song[:artist]).to be_a(String)
        expect(song[:url]).to be_a(String)
      end

      it "returns a song for a valid occasion" do
        song = recommender.recommend(category_type: :occasion, category_name: "Dance Battle")

        expect(song).to be_a(Hash)
        expect(song[:title]).not_to be_empty
        expect(song[:artist]).not_to be_empty
      end

      it "returns nil for an unknown category" do
        song = recommender.recommend(category_type: :mood, category_name: "Nonexistent Mood")
        expect(song).to be_nil
      end

      it "returns different songs on repeated calls (probabilistic)" do
        songs = 10.times.map { recommender.recommend(category_type: :mood, category_name: "Rage") }
        titles = songs.map { |s| s[:title] }.uniq
        expect(titles.length).to be >= 2
      end
    end
  end

  describe "fallback data integrity" do
    it "loads fallback data with moods and occasions" do
      data_path = File.join(__dir__, "../src/data/songs.json")
      data = JSON.parse(File.read(data_path))

      expect(data["moods"]).to be_a(Hash)
      expect(data["occasions"]).to be_a(Hash)
      expect(data["moods"].keys).to include("Rage", "In love", "Blue")
      expect(data["occasions"].keys).to include("Dance Battle", "Fancy Dinner Party")
    end

    it "has at least 2 songs per category" do
      data_path = File.join(__dir__, "../src/data/songs.json")
      data = JSON.parse(File.read(data_path))

      (data["moods"].values + data["occasions"].values).each do |songs|
        expect(songs.length).to be >= 2
      end
    end

    it "has required fields for each song" do
      data_path = File.join(__dir__, "../src/data/songs.json")
      data = JSON.parse(File.read(data_path))

      all_songs = data["moods"].values.flatten + data["occasions"].values.flatten
      all_songs.each do |song|
        expect(song).to have_key("title")
        expect(song).to have_key("artist")
        expect(song).to have_key("url")
        expect(song["url"]).to start_with("https://")
      end
    end
  end
end
