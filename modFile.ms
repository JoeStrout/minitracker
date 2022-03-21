// Module to read MOD music files.
// Format references:
//	http://www.aes.id.au/modformat.html
//	https://www.ocf.berkeley.edu/~eek/index.html/tiny_examples/ptmod/ap12.html


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



dump = function(path)
	globals.bs = new BinaryStream
	bs.littleEndian = false
	bs.data = file.loadRaw(path)
	name = bs.readString(20)
	print "Name: " + name + " (length " + name.len + ")"
	magicString = bs.data.utf8(1080, 4)
	if magicString[0] >= " " then
		qtySamples = 31
	else
		qtySamples = 15
	end if
	print "Magic string: " + magicString + "  -->  " + qtySamples + " samples"
	for sampleNum in range(1, qtySamples)
		sampleName = bs.readString(22)
		print "Sample " + sampleNum + ": " + sampleName
		sampleBytes = bs.readUshort * 2
		print "  " + sampleBytes + " bytes"
		fineTune = bs.readByte
		print "  finetune: " + fineTune
		volume = bs.readByte
		print "  volume: " + volume
		repeatStart = bs.readUshort * 2
		repeatLen = bs.readUshort * 2
		print "  repeat bytes " + repeatStart + " - " + repeatLen
		key.get
	end for
end function

dump "modfiles/dragnet.mod"
