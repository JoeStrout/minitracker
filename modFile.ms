// Module to read MOD music files.
// Format references:
//	http://www.aes.id.au/modformat.html
//	https://www.ocf.berkeley.edu/~eek/index.html/tiny_examples/ptmod/ap12.html

import "listUtil"

// Define a BinaryStream class, wrapping a RawData, to make
// it easier to sequentially read various values.  We'll even
// go so far as to include some readers for the weird data
// formats used by MOD files.
BinaryStream = {}
BinaryStream.data = null  // a RawData object
BinaryStream.pos = 0

BinaryStream.readString = function(length, trimNulls=true)
	result = self.data.utf8(self.pos, length)
	self.pos = self.pos + length
	if trimNulls then
		lastNull = 0
		for i in range(-1, -length)
			if result[i].code != 0 then
				lastNull = i+1
				break
			end if
		end for
		if lastNull then result = result[:lastNull]
	end if
	return result
end function

BinaryStream.readUshort = function
	result = self.data.ushort(self.pos)
	self.pos = self.pos + 2
	return result
end function

BinaryStream.readByte = function
	result = self.data.byte(self.pos)
	self.pos = self.pos + 1
	return result
end function

BinaryStream.readSbyte = function
	result = self.data.sbyte(self.pos)
	self.pos = self.pos + 1
	return result
end function

// Define a class to represent a MOD song.
Song = {}
Song.name = ""
Song.samples = null  	// 0-based list of Samples
Song.patSequence = null	// 0-based list of indexes into patterns, to be played in order
Song.patterns = null	// 0-based list of Patterns

// Define a class to represent one sample (digitized sound).
Sample = {}
Sample.name = ""
Sample.waveform = null		// list of values in range [-1, 1]
Sample.load = function(bs)
	samp = new Sample
	samp.name = bs.readString(22)
	samp.bytes = bs.readUshort * 2
	samp.fineTune = bs.readByte
	samp.volume = bs.readByte
	samp.repeatStart = bs.readUshort * 2
	samp.repeatLen = bs.readUshort * 2
	print "Sample " + samp.name + " has " + samp.bytes + " bytes"
	return samp
end function
Sample.loadWaveform = function(bs)
	print "Loading " + self.bytes + " for " + self.name
	if self.bytes < 1 then
		self.waveform = []
	else
		self.waveform = [0] * self.bytes
		for i in range(0, self.bytes-1)
			self.waveform[i] = bs.readSbyte / 127		
		end for
	end if
end function
Sample.getSound = function
	snd = new Sound
	duration = self.waveform.len / 8287
	freq = 1 / duration
	snd.init duration, freq, 1, self.waveform
	// Note: this sets the sound up to be played at C3
	// (period 428 by MOD standards).  To get the proper
	// speed for any period, use 428/period.
	return snd
end function

// Define a class to represent one pattern (one measure or phrase of music)
Pattern = {}
Pattern.load = function(bs)
	pat = new Pattern
	pat.notes = list.init2d(64, 4)  // indexed by [division][channel]
	for division in range(0, 63)
		for channel in range(0, 3)
			pat.notes[division][channel] = Note.load(bs)
		end for
	end for
	return pat
end function
	

// Define a little object to hold a note or effect for one channel.
Note = {}
Note.sampleNumber = 0	// 1-based sample number to play
Note.period = 0    		// frequency (more or less)
Note.effect = null 		// three-part effect spec, each value 0-15
Note.load = function(bs)
	note = new Note
	// The storage for a note is really weird.  See the docs.
	b1 = bs.readByte
	b2 = bs.readByte
	b3 = bs.readByte
	b4 = bs.readByte
	note.sampleNumber = bitAnd(b1, 240) + floor(b3 / 16)
	note.period = (b1 % 16) * 256 + b2
	note.effect = [b3 % 16, floor(b4 / 16), b4 % 16]
	return note
end function

// And, here's the code to create a song from a data file.
Song.load = function(rawDataOrPath)
	globals.song = new Song
	bs = new BinaryStream
	if rawDataOrPath isa RawData then
		bs.data = rawDataOrPath
	else
		bs.data = file.loadRaw(rawDataOrPath)
	end if
	bs.data.littleEndian = false
	print "Reading " + rawDataOrPath + ", " + bs.data.len + " bytes"
	
	song.name = bs.readString(20)
	print "Name: " + song.name
	song.magicString = bs.data.utf8(1080, 4)
	if song.magicString[0] >= " " then
		song.samples = [null] * 31
	else
		song.samples = [null] * 15
	end if
	print "Magic string: " + song.magicString + "  -->  " + song.samples.len + " samples"
	for i in song.samples.indexes
		song.samples[i] = Sample.load(bs)
	end for
	
	songLength = bs.readByte  // (number of patterns used)
	ignored = bs.readByte	// (generally 127)
	song.patSequence = []
	for i in range(1, songLength)
		song.patSequence.push(bs.readByte)
	end for
	bs.pos = bs.pos + (128-songLength)  // (skip unused pattern slots)
	magicStringAgain = bs.readString(4)
	print "Magic string (again): " + magicStringAgain
	
	song.patterns = []
	maxPat = song.patSequence.max
	for i in range(1, maxPat)
		song.patterns.push Pattern.load(bs)
	end for
	
	for samp in song.samples
		samp.loadWaveform bs
	end for
	
	return song
end function

song = Song.load("modfiles/dragnet.mod")
