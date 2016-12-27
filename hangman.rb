require "yaml"

class Hangman
	def initialize
	#initialize all game tracking variables, hangman prompts, and answer/guess arrays
		@player_name, @won, @wins, @losses, @guess_count, @number_of_wins, @difficulty, @turns, @word = "",0,0,0,0,0,0,0,""
		@prompts = ["\nAlright - spit it out. What's your letter?", "\nI ain't got all day, what's your guess?", "\nWhat are you looking at? Give me your guess...unless you've given up"]
		@bad_guesses = ["\nBoy you better hope your next guess is better than that one..", "\nI hate to see a naiive soul like yours go so soon", "\n*Shakes Head* No, kid. *Pulls off Cowboy Hat* *Wipes Brow* *Replaces Hat*"]
		@good_guesses = ["\nThere might be a place for you shovelin' manure out back of my saloon, kid", "\nShoooo doggy. This cowpoke might just live to see another day!", "\nYou make sure to tell your mama thank you for that brain of yours."]
		@game_loss = ["\nI'd be lying if I said I didn't enjoy this. Heave ho!", "\nKid, maybe in another life. *Slowly pulls lever*", "\nAnother one bites the dust *grabs crotch and pulls lever*", "\nTell your grandpappy that you're sorry you couldn't guess a stupid word"]
		@game_win = ["\nKid, you're alright.", "\nI never thought I'd see the day.", "\nI knew there was somethin special about you the minute you walked up", "\nWelcome to town, let me buy you a whiskey", "\nYou're in, but this ain't over kid."]
		@answer, @previous_guesses, @save_array = [], [], []
		#load a game or start a new game and set difficulty
		self.play
		#load the dictionary, pick a word, and set the empty array to display
		self.load_word
	end

	def new_game
		puts "\nYou've solved the riddle #{@wins} time(s) and died #{@losses} time(s)."
		puts "\nDo you want to push your luck, and play again? (y/n)"
		play_again = gets.chomp.downcase
		if self.verify_yn(play_again)
			if play_again == "y"
				@guess_count, @turns, @answer, @previous_guesses = 0,0,[],[]
				self.difficulty_setting
				self.set_guesses
				self.load_word
			else
				puts "Peace up, A-town. yayuh"
				exit
			end
		else
			self.new_game
		end
	end

	def load_game
		#display available games
		if File.exists?("saved_games")
			puts "\nWhat's was your name again, kid? Here's all the folks I got in boots at the moment:"
			puts Dir.entries("saved_games").select {|f| !File.directory? f}
			puts ""
			@player_name = gets.chomp
			@save_array = YAML.load(File.read("saved_games/#{@player_name}"))
			@player_name, @won, @wins, @losses, @guess_count, @number_of_wins, @difficulty, @turns, @word, @answer, @previous_guesses = @save_array[0], @save_array[1], @save_array[2], @save_array[3], @save_array[4], @save_array[5], @save_array[6], @save_array[7], @save_array[8], @save_array[9], @save_array[10]
			self.game_status
		else
			puts "\nI ain't got nobody saved in boots right now, you're a stranger to me. How bout we just start fresh? I ain't giving you an option here.\n\n"
			self.play
		end
		#initialize game
	end

	def save_game
		directory_name = "saved_games"
		Dir.mkdir(directory_name) unless File.exists?(directory_name)
		@save_array = [@player_name, @won, @wins, @losses, @guess_count, @number_of_wins, @difficulty, @turns, @word, @answer, @previous_guesses]
		File.open("saved_games/#{@player_name}", "w") {|f| f.write(YAML.dump(@save_array))}
		exit
	end

	def load_word 
	#load the dictionary file, downcase all the words and select a random word between 5 and 12 letters
		dictionary = []
		dictionary_file = File.open("5desk.txt")
		while !dictionary_file.eof?
			line = dictionary_file.readline.chomp
			dictionary << line.downcase if line.length > 4 && line.length < 13
		end
		@word = dictionary.sample
		@word.length.times {@answer << "_"}
		self.game_status
	end

	def play
	#Option to load a game, or set the difficulty for a new game
		puts "You look kinda familiar, have you been here before? (load a previous game?) (y/n)"
		load_game = gets.chomp
		if self.verify_yn(load_game)
			if load_game == "y"
				self.load_game
				return
			else
				puts "What's your name, kid?"
				@player_name = gets.chomp
				@difficulty = self.difficulty_setting
				self.set_guesses
			end
		else
			self.play
		end
	end

	def difficulty_setting
	#set difficulty level of game
		puts "What difficulty level, #{@player_name}? (1-easy, 2-medium, 3-hard, 4-expert)"
		difficulty = gets.chomp.to_i
		return self.verify_difficulty(difficulty)
	end

	def set_guesses
	#set number of guesses based on difficulty selected
		case @difficulty
		when 1
			@guess_count = 12
		when 2
			@guess_count = 10
		when 3
			@guess_count = 8
		when 4
			@guess_count = 6
		end
	end

	def game_status
	#gives number of tries left and current status of the answer
		self.check_win
		if @turns != 0
			puts "\nYou got #{@guess_count} tries left. Here's what you got so far, cowpoke"
		else
			puts "\nWelcome to town, stranger. It's high noon. Better guess the word quick if you ever want to leave. You get #{@guess_count} wrong answers before we hang your sorry soul."
		end
		print "\" #{@answer.join(' ')} \"\n"
		self.take_turn
	end

	def check_win
		if @guess_count == 0
			puts @game_loss.sample
			@losses += 1
		elsif @answer.join == @word
			puts @game_win.sample
			@wins += 1
		else
			return
		end
		puts "The answer was: #{@word}"
		self.new_game
	end



	def take_turn
	#gets a letter from the user, verifies that it is a letter and hasn't been guessed, checks to see if it is valid, then returns status of game
		puts "\nBefore you start - would you like to put this in a boot that we can pick up later? I got whiskey getting warm at the bar. (y/n)"
		save_game = gets.chomp.downcase
		if self.verify_yn(save_game)
			if save_game == "n"
				puts @prompts.sample
				guess = gets.chomp.downcase
				self.verify_guess(guess)
				self.check_guess(guess)
				self.game_status
			else
				self.save_game
			end
		else
			self.take_turn
		end
	end

	def check_guess(guess)
	#checks if the guess is in the answer
		if !@word.include?(guess)
			puts @bad_guesses.sample
			@guess_count -= 1
		else
			puts @good_guesses.sample
			self.correct_guess(guess)
		end
	end

	def correct_guess(guess)
	#if there is a correct guess, place it in the @answer array
		for i in 0..@word.length
			@answer[i] = guess if @word[i] == guess
		end
	end

	def verify_yn(response)
	#verifies that a y/n response is a y or n
		if response == "y" || response == "n"
			return response
		else
			puts "That is not a valid answer, use 'y' or 'n'"
			return false
		end
	end

	def verify_difficulty(response)
	#verifies that the difficulty response is an integer between 1 and 4
		if response >= 1 && response <= 4
			return response
		else
			puts "That is not a valid difficulty level, use 1, 2, 3, or 4"
			self.difficulty_setting
		end
	end

	def verify_guess(response)
	#checks if the guess is between a and z and hasn't been guessed already
		if ('a'..'z') === response && !@previous_guesses.include?(response)
			(@turns += 1) ; (@previous_guesses << response) ; return response
		elsif !('a'..'z').include?(response)
			puts "Bad guess, stranger. Maybe you don't understand your situation. Give me an english letter between a and z or I'll hang you up right now."
		else
			puts "You must be stupid - you already guessed that. I'm feeling generous, try again"
		end
		self.take_turn
	end
end

new_game = Hangman.new