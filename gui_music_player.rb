require 'rubygems'
require 'gosu'

TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
BACKGROUND_COLOR = Gosu::Color.argb(0xff_eeeeee)
COVER_WIDTH = 250

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

module Genre
  RAP, POP, CLASSIC, JAZZ, ROCK = *1..5
end

module Window
	ALBUMS, TRACKS = *0..1
end

GENRE_NAMES = ['Null', 'Rap', 'Pop', 'Classic', 'Jazz', 'Rock']

class Album
	attr_accessor :title, :artist, :genre, :cover, :tracks

	def initialize (title, artist, genre, cover, tracks)
		@title = title
		@artist = artist
        @genre = genre
		@cover = cover
		@tracks = tracks
	end
end

class Track
	attr_accessor :title, :location

	def initialize (title, location)
		@title = title
		@location = location
	end
end

def read_track(file)
    track_name = file.gets.chomp
    track_location = file.gets.chomp
    return Track.new(track_name, track_location)
end

def read_tracks(file)
    tracks = []
    count = file.gets.to_i
    i = 0
    while i < count
        tracks << read_track(file)
        i += 1
    end
    return tracks
end

def read_album(file)
    title = file.gets.chomp
    artist = file.gets.chomp
    genre = file.gets.chomp.to_i
	cover = file.gets.chomp
    tracks = read_tracks(file)
    return Album.new(title, artist, genre, cover, tracks)
end

def read_albums()
    albums = []
    file = File.new('albums.txt', 'r')
    count = file.gets.to_i
    i = 0
    while i < count
        albums << read_album(file)
        i += 1
    end
    file.close
    return albums
end

class MusicPlayer < Gosu::Window

	def initialize
	    super 500, 700
	    self.caption = "Music Player"

		@albums = read_albums()
		@big_font = Gosu::Font.new(22)
		@small_font = Gosu::Font.new(16)

		@window_type = Window::ALBUMS
		@selected_album = 0
		@selected_track = 0
		@change_track = true
		@manual_pause = false
		@first_track_position = 0
	end

    def draw_albums_window(albums)
		select_prompt = "Select the album you want to play"
		x_select = (480 - @big_font.text_width(select_prompt, 1.0)) / 2
		@big_font.draw_markup("<b>#{select_prompt}</b>", x_select, 60, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
		if (@selected_album > 0)
			previous_album = Gosu::Image.new("buttons/Previous_Album.png")
			previous_album.draw(25, 270, ZOrder::UI, scale_x = 1.0, scale_y = 1.0)
		end

		if (@selected_album < albums.length - 1)
			next_album = Gosu::Image.new("buttons/Next_Album.png")
			next_album.draw(425, 270, ZOrder::UI, scale_x = 1.0, scale_y = 1.0)
		end

		album = albums[@selected_album]
		cover = Gosu::Image.new("images/#{album.cover}.png")
		cover.draw(100, 120, ZOrder::UI, scale_x = 1.2, scale_y = 1.2)

		x_text = 250
		x_minus = @big_font.text_width(album.title, 1.0) / 2.0
		y_text = 455
		@big_font.draw_markup("<b>#{album.title}</b>", x_text - x_minus, y_text, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)

		x_text = 250
		x_minus = @big_font.text_width(album.artist, 1.0) / 2.0
		y_text = 490
		@big_font.draw_text(album.artist, x_text - x_minus, y_text, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
			
	end

    def draw_tracks_window(album)
		home = Gosu::Image.new("buttons/Home_Button.png")
		home.draw(10, 9, ZOrder::UI)
		@small_font.draw_text("Back", 36, 12, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
		
		# Draw the album title
        header = album.title + ' - ' + album.artist
		x_header = 250
		x_minus = @big_font.text_width(header, 1.0) / 2.0
		y_header = 55
		@big_font.draw_markup("<b>#{header}</b>", x_header - x_minus, y_header, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)

		# Draw the album artwork
		cover = Gosu::Image.new("images/#{album.cover}.png")
		cover.draw(125, 85, ZOrder::UI, scale_x = 1.0, scale_y = 1.0)

		@small_font.draw_markup("<b>Tracklist</b>", 215, 360, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)

		if @first_track_position > 4
			previous_tracks = Gosu::Image.new("buttons/Previous_Tracks.png")
			previous_tracks.draw(165, 355, ZOrder::UI, scale_x = 1.0, scale_y = 1.0)
		end

		if (@first_track_position < (album.tracks.length - 4)) && (album.tracks.length > 5)
			next_tracks = Gosu::Image.new("buttons/Next_Tracks.png")
			next_tracks.draw(306, 355, ZOrder::UI, scale_x = 1.0, scale_y = 1.0)
		end

		# Draw the tracks
		Gosu.draw_rect(125, 345, 250, 200, Gosu::Color.argb(0xff_cdcdcd), ZOrder::PLAYER, mode=:default)
		y = 0
		
		
		i = @first_track_position
		while i < [album.tracks.length, (@first_track_position + 5)].min
			track = album.tracks[i]
			y_track = 395 + y * 30

			track_title = track.title
			track_color = Gosu::Color::BLACK
			if i == @selected_track
				track_title = "<b>#{track.title}</b>"
				track_color = Gosu::Color.argb(0xff_c71585)
				if @change_track
					@song = Gosu::Song.new(track.location)
					@song.play(false)
					@change_track = false
				end
			end
			@small_font.draw_markup(track_title, 135, y_track, ZOrder::UI, 1.0, 1.0, track_color)
			i += 1
			y += 1
		end

		if not @song.playing? and not @manual_pause
			@selected_track = (@selected_track + 1) % album.tracks.length
			@change_track = true
		end

		# Draw media buttons
		media = Gosu::Image.new("buttons/Media_Buttons.png")
		media.draw(154, 565, ZOrder::UI)
	end

	# Draw a coloured background using TOP_COLOR and BOTTOM_COLOR

	def draw_background
		Gosu.draw_rect(0, 0, 500, 700, BACKGROUND_COLOR, ZOrder::BACKGROUND, mode=:default)
	end

	# Handle the button_down event
	def mouse_albums(x, y)
		if ((x.between?(425, 475) && y.between?(270, 320)) && @selected_album < (@albums.length - 1))
			@selected_album += 1
		end

		if ((x.between?(25, 75) && y.between?(270, 320)) && @selected_album > 0)
			@selected_album -= 1
		end

		if (x.between?(100, 400) && y.between?(120, 420)) 
			@window_type = Window::TRACKS
		end
				
	end

	def mouse_tracks(x, y)

		if ((x.between?(306, 336) && y.between?(355, 385)) && ((@first_track_position + 5) < @albums[@selected_album].tracks.length))
			@first_track_position += 5
		end

		if ((x.between?(165, 195) && y.between?(355, 385)) && @first_track_position > 4)
			@first_track_position -= 5
		end

		# Back to home
		if x.between?(10, 10 + 22 + @small_font.text_width("Back", 1.0)) && y.between?(9, 9 + 22)
			@window_type = Window::ALBUMS
			@selected_track = 0
			@song.stop
			@change_track = true
			@manual_pause = false
		end
	
		# Select track
		i = @first_track_position
		y_click = 0
		while i < [@albums[@selected_album].tracks.length, (@first_track_position + 5)].min
			if x.between?(125, 125 + 250) && y.between?(395 + y_click * 30, 395 + y_click * 30 + 20)
				if @selected_track != i
					@selected_track = i
					@change_track = true
				end
			end
			i += 1
			y_click += 1
		end

		# Media buttons
		# Previous
		if x.between?(154, 154 + 50) && y.between?(565, 565 + 50)
			
			if (@selected_track == (@first_track_position)) && @first_track_position != 0
				@first_track_position -= 5
			end
			
			@song.stop
			if @selected_track != 0
				@selected_track = (@selected_track - 1) % @albums[@selected_album].tracks.length
			end
			@change_track = true
		end

		# Play/Pause
		if x.between?(225, 225 + 50) && y.between?(565, 565 + 50)
			if @song.playing?
				@song.pause
				@manual_pause = true
			else
				@song.play
				@manual_pause = false
			end
		end

		# Next
		if x.between?(296, 296 + 50) && y.between?(565, 565 + 50)
			if (@selected_track == (@first_track_position + 4)) && (@first_track_position < (@albums[@selected_album].tracks.length - 4)) && (@albums[@selected_album].tracks.length > 5)
				@first_track_position += 5
			end
			
			@song.stop
			if @selected_track < @albums[@selected_album].tracks.length - 1
				@selected_track = (@selected_track + 1) % @albums[@selected_album].tracks.length
			end
			@change_track = true
		end
	end

	def draw
		draw_background()

		case @window_type
		when Window::ALBUMS
			draw_albums_window(@albums)
		when Window::TRACKS
			draw_tracks_window(@albums[@selected_album])
		end

		# Draw credit
		credit_text = "Quoc Phi Long Pham - 104771041"
		x_credit = (500 - @small_font.text_width(credit_text, 1.0)) / 2
		@small_font.draw_text(credit_text, x_credit, 666, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
	end

 	def needs_cursor?; true; end

	def button_down(id)
		case id
	    when Gosu::MsLeft
			case @window_type
			when Window::ALBUMS
				mouse_albums(mouse_x, mouse_y)
			when Window::TRACKS
				mouse_tracks(mouse_x, mouse_y)
			end
	    end
	end

end

MusicPlayer.new.show