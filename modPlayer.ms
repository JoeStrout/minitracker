import "modFile"
import "stringUtil"

min = function(a,b)
	if a < b then return a else return b
end function
max = function(a,b)
	if a > b then return a else return b
end function


Channel = {}
Channel.sounds = null	// array of Sounds for use by this channel
Channel.volFactor = 1	// volume factor (used to quiet or mute channel)
Channel.pan = 0			// stereo pan for this channel
Channel.curSound = null	// currently playing sound
Channel.curVolume = 1	// current volume (0-1)
Channel.curPeriod = 428	// current period
Channel.curSlidePerTick	= 0 // slide per tick to apply (from effects 1-2)
Channel.startTime = 0	// time at which we started playing curSound
Channel.rect = null		// left, bottom, width, height
Channel.lastMeterLevel = 0
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
		self.startTime = time
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
Channel.level = function
	// Compute the current sound level, 0-1, based on the current time,
	// and the current sound speed and start time.
	if not self.curSound or self.curVolume == 0 then return 0
	wave = self.curSound.waveform
	speed = 428 / self.curPeriod  // note this will be slightly off if period changes during play, but close enough
	waveSamplesPerSec = 8287 / speed
	t = time - self.startTime
	curSample = t * waveSamplesPerSec
	if curSample > wave.len then return 0
	startSample = max(0, curSample - 25)
	endSample = min(wave.len, curSample + 25)
	globals.samples = wave[startSample:endSample]
	return (samples.max - samples.min) / 2
end function
Channel.updateMeter = function
	newLevel = self.level
	if newLevel == self.lastMeterLevel then return
	r = self.rect
	if newLevel > self.lastMeterLevel then
		gfx.fillRect r.left, r.bottom + r.height * self.lastMeterLevel,
		  r.width, floor((newLevel - self.lastMeterLevel) * r.height), color.yellow
	else
		gfx.fillRect r.left, r.bottom + r.height * newLevel,
		  r.width, ceil((self.lastMeterLevel - newLevel) * r.height), color.black
	end if
	self.lastMeterLevel = newLevel
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
		chan.rect = {"left":0, "bottom":500, "width":32, "height":100}
		chan.rect.left = 50 + 208 * channel
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
		self.channels[chanNum].updateMeter
	end for
	
	self.nextDiv = self.nextDiv + 1
	if self.nextDiv > 63 then
		self.beginStep self.step + 1
	end if
end function

Player.tick = function
	for chan in self.channels
		chan.tick
		chan.updateMeter
	end for
end function

clear

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
