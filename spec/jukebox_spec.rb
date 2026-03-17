# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe Jukebox do
  subject(:jukebox) { described_class.new }

  describe "#running?" do
    it "is true on initialization" do
      expect(jukebox.running?).to be true
    end
  end

  describe "constants" do
    it "defines 6 moods" do
      expect(Jukebox::MOODS.length).to eq(6)
    end

    it "defines 6 occasions" do
      expect(Jukebox::OCCASIONS.length).to eq(6)
    end

    it "moods are frozen" do
      expect(Jukebox::MOODS).to be_frozen
    end

    it "occasions are frozen" do
      expect(Jukebox::OCCASIONS).to be_frozen
    end
  end
end
