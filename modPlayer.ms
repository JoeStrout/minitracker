import "modFile"
import "stringUtil"

Channel = {}
Channel.sounds = null	// array of Sounds for use by this channel
Channel.volFactor = 1	// volume factor (used to quiet or mute channel)
Channel.pan = 0			// stereo pan for this channel
Channel.curSound = null	// currently playing sound
Channel.curVolume = 1	// current volume (0-1)
Channel.curPeriod = 428	// current period
Channel.curSlidePerTick	= 0 // slide per tick to apply (from effects 1-2)
Channel.applyNote = function(note)
	if note.sampleNumber != 0 and note.period > 0 then
		if self.curSound != null then self.curSound.stop
		self.curVolume = 1
		if note.sampleNumber <= self.sounds.len then
			self.curSound = self.sounds[note.sampleNumber]
			self.curPeriod = note.period
			self.curSound.play self.curVolume, self.pan, 428 / self.curPeriod
		else
			self.curSound = null
		end if
		self.curPeriod = note.period
	end if
	self.curSlidePerTick = 0
	if note.effect[0] == 1 then			// slide up
		self.curSlidePerTick = -(note.effect[1]*16 + note.effect[2])
	else if note.effect[0] == 2 then	// slide down
		self.curSlidePerTick = (note.effect[1]*16 + note.effect[2])
	else if note.effect[0] == 12 then	// set volume
		vol = note.effect[1] * 16 + note.effect[2]  // volume 0-64
		self.curVolume = vol / 64
		if self.curSound != null then
			self.curSound.adjust self.curVolume, self.pan, 428 / self.curPeriod
		end if
	end if
end function
Channel.tick = function(note)
	if self.curSlidePerTick then
		self.curPeriod = self.curPeriod + self.curSlidePerTick
		if self.curSound != null then
			self.curSound.adjust self.curVolume, self.pan, 428 / self.curPeriod
		end if
	end if
end function	

Player = {}
Player.song = null		// Song we are playing
Player.step = 0			// which step in song.patSequence we're on
Player.curPat = null	// Pattern we are currently playing
Player.nextDiv = 0		// current division (tick within pattern)
Player.channels = null	// list of 4 Channel s
Player.done = false

Player.init = function(song)
	self.song = song
	self.channels = []
	for channel in range(0,3)
		chan = new Channel
		self.channels.push chan
		if channel == 0 or channel == 4 then
			chan.pan = -1
		else
			chan.pan = 1
		end if
		chan.sounds = [null]  // push a null, to get 1-based indexing
		for samp in song.samples
			chan.sounds.push samp.getSound
		end for
	end for
	self.beginStep 2
end function

Player.beginStep = function(stepNum)
	self.step = stepNum
	if stepNum >= song.patSequence.len then
		self.done = true
		return
	end if
	self.done = false
	patNum = song.patSequence[self.step]
	self.curPat = song.patterns[patNum]
	self.nextDiv = 0
	print "Step " + stepNum + ", pattern " + patNum
end function

Player.advance = function
	print self.curPat.getString(self.nextDiv)
	for chanNum in range(0, 3)
		note = self.curPat.notes[self.nextDiv][chanNum]
		self.channels[chanNum].applyNote note
	end for
	
	self.nextDiv = self.nextDiv + 1
	if self.nextDiv > 63 then
		self.beginStep self.step + 1
	end if
end function

Player.tick = function
	for chan in self.channels
		chan.tick
	end for
end function

song = modFile.Song.load("modfiles/dragnet.mod")
player = new Player
player.init song
paused = false
while not player.done
	player.advance
	if paused then
		if key.get.code == 10 then paused = false
	else
		for delay in range(6)
			player.tick
			yield
		end for
		if key.available then
			key.get
			paused = true
			print "(Paused.  Press Return to resume, any other key to step.)"
		end if
	end if
end while
