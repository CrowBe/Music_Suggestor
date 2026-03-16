# frozen_string_literal: true

require "anthropic"
require "json"

# Uses Claude AI to generate personalized music recommendations.
# Falls back to the curated songs.json database when the API is unavailable.
class MusicRecommender
  FALLBACK_DATA_PATH = File.join(__dir__, "data", "songs.json")

  def initialize
    @client = build_client
    @fallback_data = load_fallback_data
  end

  # Returns a song hash with :title, :artist, :url, :reason keys.
  # category_type is :mood or :occasion, category_name is the selected label.
  def recommend(category_type:, category_name:, user_name: nil)
    if @client
      recommend_with_ai(category_type: category_type, category_name: category_name, user_name: user_name)
    else
      recommend_from_fallback(category_type: category_type, category_name: category_name)
    end
  end

  def ai_available?
    !@client.nil?
  end

  private

  def build_client
    api_key = ENV["ANTHROPIC_API_KEY"]
    return nil if api_key.nil? || api_key.strip.empty? || api_key == "your_api_key_here"

    Anthropic::Client.new(api_key: api_key)
  rescue StandardError
    nil
  end

  def load_fallback_data
    JSON.parse(File.read(FALLBACK_DATA_PATH))
  rescue StandardError
    { "moods" => {}, "occasions" => {} }
  end

  def recommend_with_ai(category_type:, category_name:, user_name:)
    greeting = user_name ? "The user's name is #{user_name}. " : ""
    type_label = category_type == :mood ? "mood" : "occasion"

    prompt = <<~PROMPT
      #{greeting}Recommend ONE song that perfectly fits the #{type_label}: "#{category_name}".

      Respond with ONLY valid JSON in this exact format, no other text:
      {
        "title": "Song Title",
        "artist": "Artist Name",
        "url": "https://www.youtube.com/watch?v=VIDEOID",
        "reason": "One sentence explaining why this song fits the #{type_label}"
      }

      Rules:
      - Pick a real, well-known song
      - Use a real YouTube URL (youtube.com/watch?v=...)
      - Keep reason to one sentence
      - Do not include markdown formatting
    PROMPT

    response = @client.messages.create(
      model: :"claude-opus-4-6",
      max_tokens: 256,
      messages: [{ role: "user", content: prompt }]
    )

    text = response.content.find { |b| b.type == :text }&.text || ""
    parse_ai_response(text)
  rescue StandardError
    recommend_from_fallback(category_type: category_type, category_name: category_name)
  end

  def parse_ai_response(text)
    json_text = text.gsub(/```(?:json)?/, "").strip
    data = JSON.parse(json_text)
    {
      title: data["title"] || "Unknown",
      artist: data["artist"] || "Unknown",
      url: data["url"] || "",
      reason: data["reason"]
    }
  rescue JSON::ParserError
    nil
  end

  def recommend_from_fallback(category_type:, category_name:)
    collection = category_type == :mood ? @fallback_data["moods"] : @fallback_data["occasions"]
    songs = collection[category_name] || []
    return nil if songs.empty?

    song = songs.sample
    {
      title: song["title"],
      artist: song["artist"],
      url: song["url"],
      reason: nil
    }
  end
end
