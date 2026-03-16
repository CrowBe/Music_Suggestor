# frozen_string_literal: true

require "dotenv/load"
require_relative "Jukebox"

jukebox = Jukebox.new
jukebox.greeting

while jukebox.running?
  type = jukebox.choose_category_type
  category = jukebox.choose_category(type)
  jukebox.suggest_song(type, category)
  jukebox.ask_for_another
end
