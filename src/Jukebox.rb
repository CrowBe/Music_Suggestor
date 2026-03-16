# frozen_string_literal: true

require "colorize"
require_relative "music_recommender"

class Jukebox
  MOODS = [
    "On top of the world",
    "Blue",
    "In love",
    "Sleep deprived",
    "Rage",
    "A little high"
  ].freeze

  OCCASIONS = [
    "Netflix & Chill",
    "Dance Battle",
    "Fantasy Board Game Night",
    "Cosplay Party",
    "Fancy Dinner Party",
    "Hangin' Out With Garret"
  ].freeze

  def initialize
    @recommender = MusicRecommender.new
    @user_name = nil
    @running = true
  end

  def running?
    @running
  end

  def greeting
    puts "\n" + "╔══════════════════════════════════════╗".colorize(:light_magenta)
    puts       "║   Ben & Mike's Song Suggestor  v2.0  ║".colorize(:light_magenta)
    puts       "╚══════════════════════════════════════╝".colorize(:light_magenta)

    if @recommender.ai_available?
      puts "  ✨ AI-powered recommendations enabled".colorize(:light_green)
    else
      puts "  📀 Running in curated mode (set ANTHROPIC_API_KEY for AI recommendations)".colorize(:yellow)
    end

    puts "\nWhat can we call you? ".colorize(:light_cyan)
    @user_name = gets&.chomp&.strip
    @user_name = nil if @user_name&.empty?
  end

  def choose_category_type
    name = @user_name ? "#{@user_name}!" : "there!"
    puts "\nHello #{name} Would you like a song for a:".colorize(:light_white)

    choice = prompt_choice([
      "  1.  Mood   ".colorize(:light_red),
      "  2.  Occasion   ".colorize(:light_yellow)
    ])

    choice == 1 ? :mood : :occasion
  end

  def choose_category(type)
    if type == :mood
      puts "\nHow are you feeling?".colorize(:light_white)
      items = MOODS
      color = :light_red
    else
      puts "\nWhat's the occasion?".colorize(:light_white)
      items = OCCASIONS
      color = :light_yellow
    end

    numbered = items.each_with_index.map { |name, i| "  #{i + 1}.  #{name}  ".colorize(color) }
    index = prompt_choice(numbered) - 1
    items[index]
  end

  def suggest_song(type, category_name)
    puts "\n  🎵 Finding the perfect song...".colorize(:light_cyan) if @recommender.ai_available?

    song = @recommender.recommend(
      category_type: type,
      category_name: category_name,
      user_name: @user_name
    )

    if song
      display_song(song)
    else
      puts "\n  Sorry, couldn't find a song for that selection.".colorize(:light_red)
    end
  end

  def ask_for_another
    puts "\n  Would you like another suggestion?".colorize(:light_white)
    choice = prompt_choice([
      "  1.  Yes, please!   ".colorize(:light_green),
      "  2.  No thanks, I'm done   ".colorize(:light_red)
    ])

    if choice == 1
      @running = true
    else
      @running = false
      puts "\nThanks for using Ben & Mike's Song Suggestor! Enjoy the music! 🎶\n".colorize(:light_magenta)
    end
  end

  private

  def display_song(song)
    puts "\n" + "─" * 42
    puts "  🎵  #{song[:title]}".colorize(:light_white)
    puts "  👤  #{song[:artist]}".colorize(:light_white)
    puts "  🔗  #{song[:url]}".colorize(:light_cyan) unless song[:url].to_s.empty?
    puts "  💡  #{song[:reason]}".colorize(:light_yellow) if song[:reason]
    puts "─" * 42
  end

  def prompt_choice(options)
    valid_range = (1..options.length)
    choice = nil

    until valid_range.cover?(choice)
      puts "\n"
      options.each { |opt| puts opt }
      print "\n  Enter a number (#{valid_range.min}-#{valid_range.max}): "
      choice = gets&.to_i

      unless valid_range.cover?(choice)
        puts "  Invalid choice. Please enter a number between #{valid_range.min} and #{valid_range.max}.".colorize(:light_red)
      end
    end

    choice
  end
end
