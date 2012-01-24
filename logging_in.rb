# coding: utf-8
#
# DISCLAIMER:
# This file was written without extensive testing, and is merely an
# example. Before using this yourself, I advice you to look through
# the code carefully.
#

$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'hallon'
require './spotify_config'

# Utility
def prompt(str)
  print str
  gets.chomp
end

class Track
  attr_accessor :name, :artist, :popularity

  def initialize(name, artist, pop)
    @name, @artist, @popularity = name, artist, pop
  end

  def <=>(track)
    @popularity <=> track.popularity
  end

  def to_s
    "#@name #@artist #@popularity"
  end
end

session = Hallon::Session.initialize IO.read(ENV['HALLON_APPKEY']) do
  on(:log_message) do |message|
    puts "[LOG] #{message}"
  end

  on(:connection_error) do |error|
    Hallon::Error.maybe_raise(error)
  end

  on(:logged_out) do
    abort "[FAIL] Logged out!"
  end
end

session.login!(ENV['HALLON_USERNAME'], ENV['HALLON_PASSWORD'])

puts "Successfully logged in!"

username = prompt("Enter a Spotify username: ")
    puts "Fetching container for #{username}..."
    published = Hallon::User.new(username).published
    session.wait_for { published.loaded? }

    puts "Listing #{published.size} playlists."
    published.contents.each do |playlist|
     next if playlist.nil? # folder or somesuch

      session.wait_for { playlist.loaded? }

      tracks = Array.new

      playlist.tracks.each_with_index do |track, i|
        session.wait_for { track.loaded? }

        #puts "\t (#{i+1}/#{playlist.size}) #{track.name} #{track.popularity.to_f.to_s}"
        currentTrack = Track.new(track.name, track.artist.name, track.popularity.to_f)
        tracks.push(currentTrack)
      end

      tracks.sort!.reverse!

      if playlist.name.include? "Best" then

        puts playlist.name

        tracks.each do |t|
          puts t
        end
      end
    end
