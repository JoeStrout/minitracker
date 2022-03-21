import "modFile"
import "stringUtil"

Player = {}
Player.song = null		// Song we are playing
Player.step = 0			// which step in song.patSequence we're on
Player.curPat = null	// Pattern we are currently playing
Player.nextDiv = 0		// current division (tick within pattern)
Player.channels = null	// 4 current Sounds (one for each channel)
Player.sounds = null	// 2D array of Sound by [channel][sample]
Player.pan = [-1, 1, 1, 1]  // pan value for each channel

Player.init = function(song)
	self.song = song
	self.channels = [null] * 4
	self.sounds = []
	for channel in range(0,3)
		self.sounds.push [null]  // push a null, to get 1-based indexing
		for samp in song.samples
			self.sounds[channel].push samp.getSound
		end for
	end for
	self.beginStep 0
end function

Player.beginStep = function(stepNum)
	self.step = stepNum
	patNum = song.patSequence[self.step]
	self.curPat = song.patterns[patNum]
	self.nextDiv = 0
	print "Step " + stepNum + ", pattern " + patNum
end function

Player.advance = function
	print self.curPat.getString(self.nextDiv)
	for channel in range(0, 3)
		note = self.curPat.notes[self.nextDiv][channel]
		// Ignoring effects for now... let's just play!
		if note.sampleNumber != 0 and note.period > 0 then
			if self.channels[channel] != null then
				self.channels[channel].stop
			end if
			snd = self.sounds[channel][note.sampleNumber]
			snd.play 1, self.pan[channel], 428 / note.period
			self.channels[channel] = snd
		end if
	end for
	
	self.nextDiv = self.nextDiv + 1
	if self.nextDiv > 63 then
		self.beginStep self.step + 1
	end if
end function


song = modFile.Song.load("modfiles/dragnet.mod")
player = new Player
player.init song
while true
	player.advance
	for delay in range(6)
		yield
	end for
	end while