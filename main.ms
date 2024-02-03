import "importUtil"
ensureImport "events"
ensureImport "listUtil"
ensureImport "mathUtil"
ensureImport "tc"
ensureImport "canon"

Display = {
    "text": display(3),
    "sprite": display(4),
}

SunsetColors = [
    "#f1671f", // bright
    "#c81b26",
    "#9b0f5f",
    "#600479",
    "#160a47", // dark
    "#000000", // overflow
]

WaterColors = [
    "#160a47", // dark
    "#600479",
    "#9b0f5f",
    "#c81b26",
    "#f1671f", // bright
    color.orange, // overflow
]

for n in range(0, WaterColors.len - 1)
	WaterColors[n] = color.lerp(WaterColors[n], "#000088", 0.5)
end for

WATER_HEIGHT = gfx.height / 3
SKY_HEIGHT = gfx.height - WATER_HEIGHT

SPEED_MULTIPLIER = 1000000
BASE_SIZE = 40
WATER_COLOR = "#000060FF"
RIPPLE_COLOR = color.white
RIPPLE_OFFSET_COLOR = color.lerp(RIPPLE_COLOR, WATER_COLOR, 0.5)
RIPPLE_LIFESPAN = 5

BALLOON_IMAGE = img("Balloon")
BALLOON_SPEED_Y = SPEED_MULTIPLIER / 2
MAX_BALLOONS = 15
BALOON_LIFESPAN = 30 // seconds

Colors = [
color.red,
color.green,
color.blue,
color.yellow,
color.aqua,
color.black,
color.brown,
color.fuchsia,
color.gray,
color.lime,
color.maroon,
color.navy,
color.olive,
color.orange,
color.pink,
color.purple,
color.silver,
color.teal,
color.white,
]

randomColor = function(alpha = 255)
	index = floor(rnd * Colors.len)
	c = color.toList(Colors[index])
	c[3] = alpha
	return color.fromList(c)
end function

Ripple = {}
Ripple.init = function(x, y)
	self.x = x
	self.y = y
	self.penSize = 2
	self.speed = 1.5
	self.isAlive = true
	self.scale = 1 - y / WATER_HEIGHT
	self.size = BASE_SIZE
	self.color = RIPPLE_COLOR
	self.offsetColor = RIPPLE_OFFSET_COLOR
	self.deathTime = time + RIPPLE_LIFESPAN
	return self
end function

Ripple.make = function(x, y)
	return (new Ripple).init(x, y)
end function

Ripple.width = function
	return self.size
end function

Ripple.height = function
	return self.size / 2 * self.scale
end function

Ripple.draw = function
	oval self.x - self.width / 2 - 1, self.y - self.height / 2 - 1, self.width, self.height, self.offsetColor, self.penSize
	oval self.x - self.width / 2, self.y - self.height / 2, self.width, self.height, self.color, self.penSize
end function

Ripple.update = function(deltaTime)
	scaleFactor = deltaTime * SPEED_MULTIPLIER
	colorFactor = scaleFactor * 0.01
	
	self.size += self.speed * scaleFactor
	self.scale -= scaleFactor * 0.001
	
	c = color.toList(self.color)
	c.multiplyBy 1 - colorFactor * (1 - self.scale)
	self.color = color.fromList(c)
	
	if c[0] < 1 then
		c = color.toList(self.offsetColor)
		c.multiplyBy 1 - colorFactor * (1 - self.scale)
		self.offsetColor = color.fromList(c)
		
		if c[0] < 1 or time > self.deathTime then self.isAlive = false
	end if
end function

Balloon = {}

Balloon.init = function(x, y, c = null)
	self.startX = x
	self.startY = y
	self.isAlive = true
	self.initialY = BALLOON_IMAGE.height
	self.deathTime = time + BALOON_LIFESPAN
	
	if c == null then
		c = randomColor(192)
	else
		c = color.toList(c)
		c[3] = 192
		c = color.fromList(c)
	end if
	
	// We're intentionally not setting the balloon image until the draw call.
	
	self.sprite = new Sprite
	self.sprite.x = x
	self.sprite.y = y
	self.sprite.scale = 1 - y / WATER_HEIGHT
	self.sprite.tint = c
	display(4).sprites.push self.sprite
	
	self.reflectedSprite = new Sprite
	self.reflectedSprite.x = x
	self.reflectedSprite.y = y
	self.reflectedSprite.scale = self.sprite.scale
	self.reflectedSprite.tint = color.toList(self.sprite.tint)
	self.reflectedSprite.tint[3] /= 2
	self.reflectedSprite.tint = color.fromList(self.reflectedSprite.tint)
	self.reflectedSprite.rotation = 180
	display(4).sprites.push self.reflectedSprite
	
	return self
end function

Balloon.make = function(x, y, c = null)
	return (new Balloon).init(x, y, c)
end function

Balloon.update = function(deltaTime)
	srcWidth = BALLOON_IMAGE.width
	
	if self.initialY == 0 then
		self.sprite.y += BALLOON_SPEED_Y * self.sprite.scale * deltaTime
		if self.sprite.y >= gfx.height or time > self.deathTime then self.isAlive = false
		
		deltaY = self.sprite.y - self.startY
		self.reflectedSprite.y = 2 * self.startY - BALLOON_IMAGE.height * self.sprite.scale - self.sprite.y
	else
		self.initialY -= BALLOON_SPEED_Y * self.sprite.scale * deltaTime
		if self.initialY < 0.0001 then
			self.initialY = 0
			self.sprite.image = BALLOON_IMAGE
			self.sprite.reflectedSprite = BALLOON_IMAGE
		end if
		
		srcHeight = BALLOON_IMAGE.height - self.initialY
		self.sprite.image = BALLOON_IMAGE.getImage(0, self.initialY, srcWidth, srcHeight)
		self.reflectedSprite.y = self.startY - srcHeight * self.sprite.scale
		self.reflectedSprite.image = self.sprite.image
	end if
end function

Balloon.cleanup = function
	display(4).sprites.removeVal self.sprite
	display(4).sprites.removeVal self.reflectedSprite
end function

generateSunset = function
	bgdsp = new PixelDisplay
	sectionSize = SKY_HEIGHT / (SunsetColors.len - 1)
	for n in range(0, SunsetColors.len - 2) // Don't render the overflow color.
		y = n * sectionSize
		
		for dy in range(0, sectionSize)
			lineY = WATER_HEIGHT + y + dy
			clr = color.lerp(SunsetColors[n], SunsetColors[n + 1], dy / sectionSize)
			penSize = 2
			bgdsp.line 0, lineY, gfx.width, lineY, clr, penSize
		end for
	end for
	
	return bgdsp.getImage(0, WATER_HEIGHT, gfx.width, SKY_HEIGHT)
end function

generateWater = function
	bgdsp = new PixelDisplay
	sectionSize = WATER_HEIGHT / (WaterColors.len - 1)
	for n in range(0, WaterColors.len - 2) // Don't render the overflow color.
		y = n * sectionSize
		
		for dy in range(0, sectionSize)
			lineY = y + dy
			clr = color.lerp(WaterColors[n], WaterColors[n + 1], dy / sectionSize)
			penSize = 2
			bgdsp.line 0, lineY, gfx.width, lineY, clr, penSize
		end for
	end for
	
	return bgdsp.getImage(0, 0, gfx.width, WATER_HEIGHT)
end function

generateBalloon = function(x=null, y=null, c=null)
	if x == null then
		// Queue up the next balloon.
		delay = 1 + rnd * 3
		events.eventLoop.doAfter delay, @generateBalloon
	end if
	
	if balloons.len >= MAX_BALLOONS then return
	
	if x == null then x = floor(rnd * gfx.width)
	if y == null then y = floor(rnd * WATER_HEIGHT)
	
	makeRipple = function()
		if ripples.len < 30 then ripples.push Ripple.make(x, y)
	end function
	
	numRipples = floor(rnd * 5) + 1
	delay = 0
	delayDelta = rnd / 4
	
	for n in range(1, numRipples)
		events.eventLoop.doAfter delay, @makeRipple
		delay += delayDelta
	end for
	
	balloons.push Balloon.make(x, y, c)
	balloons.sort "y"
	// TODO: Reverse the array here if necessary?
end function

events.eventLoop.onKeyDown["escape"] = function
	self.stop
end function

// events.eventLoop.onClick = function
// 	if mouse.button(0) then
// 		if mouse.y < WATER_HEIGHT then
// 			rx = mouse.x
// 			ry = mouse.y
// 			generateBalloon rx, ry
// 		end if
// 	end if
// end function

calculateYForNote = function(octave, noteName)
	noteNumber = canon.baseNoteForOctave(octave) + canon.Notes[noteName]
	noteLength = canon.highestNoteNumber - canon.lowestNoteNumber
	percentageDistanceInRange = (noteNumber - canon.lowestNoteNumber) / noteLength
	
	// Only allow balloons halfway up the water height.
	// Might help with performance.
	y = percentageDistanceInRange * (WATER_HEIGHT * 0.75)
	return y
end function

playQuarterNote = function
	if (canon.iteration % 5 == 0) and time >= canon.nextNoteTime then
		octave = canon.song[canon.songIndex][0] + 2
		chordName = canon.song[canon.songIndex][1]
		chord = canon.Chords[chordName]
		noteName = chord[canon.noteIndex]
		duration = canon.song[canon.songIndex][2] / 4
		
		canon.playNote(octave, noteName, duration)
		
		canon.nextNoteTime = time + duration
		
		// Allow the high notes to walk randomly.
		delta = floor(rnd * 2)
		if delta == 0 then delta = -1
		canon.noteIndex = canon.noteIndex + delta
		
		if canon.noteIndex >= chord.len then canon.noteIndex = 0
		if canon.noteIndex < 0 then canon.noteIndex = chord.len - 1
		
		x = floor(rnd * gfx.width)
		y = calculateYForNote(octave, noteName)
		generateBalloon x, y
	end if
end function

playHalfNote = function
	if (canon.iteration % 3 == 0) and time >= canon.nextHalfTime then
		octave = canon.song[canon.songIndex][0] + 1
		chordName = canon.song[canon.songIndex][1]
		chord = canon.Chords[chordName]
		duration = canon.song[canon.songIndex][2] / 2
		
		// Allow the middle notes to walk randomly.
		delta = floor(rnd * 2)
		if delta == 0 then delta = -1
		canon.halfIndex = canon.halfIndex + delta
		if canon.halfIndex >= chord.len then canon.halfIndex = 0
		if canon.halfIndex < 0 then canon.halfIndex = chord.len - 1
		noteName = chord[canon.halfIndex]
		
		canon.playHalfNote(octave, noteName, duration)
		
		canon.nextHalfTime = time + duration
		
		if canon.iteration % 5 != 0 then
			x = floor(rnd * gfx.width)
			y = calculateYForNote(octave, noteName)
			generateBalloon x, y
		end if
	end if
end function

playChord = function
	// The bass chords really need to walk sequentially.
	if time >= canon.nextChordTime then
		octave = canon.song[canon.songIndex][0]
		chordName = canon.song[canon.songIndex][1]
		duration = canon.song[canon.songIndex][2]
		
		canon.playChord(octave, chordName, duration)
		canon.nextChordTime = time + duration
		canon.songIndex += 1
		
		if canon.songIndex >= canon.song.len then
			canon.songIndex = 0
			canon.iteration += 1
		end if
		
		if (canon.iteration % 3 != 0) and (canon.iteration % 5 != 0) then
			chord = canon.Chords[chordName]
			noteName = chord[floor(rnd * 3)]
			x = floor(rnd * gfx.width)
			y = calculateYForNote(octave, noteName)
			generateBalloon x, y
		end if
	end if
end function

events.eventLoop.onUpdate = function
	clr color.clear
	
	// text.row=3
	// text.col=0
	// text.color=color.white
	// print "# balloons: " + balloons.len + "     "
	// print "# ripples: " + ripples.len + "     "
	// print "Elapsed: " + ((time - startTime) / 60) + "     "
	
	liveRipples = []
	for r in ripples
		r.update events.dt
		if r.isAlive then liveRipples.push r
		r.draw
	end for
	globals.ripples = liveRipples
	
	// Redrawing the sky overwrites any ripples that went out of bounds.
	gfx.drawImage sunsetImage, 0, WATER_HEIGHT
	
	// The balloons should be sorted ascending by "y", but we want to draw them back to front.
	liveBalloons = []
	for b in balloons //.reversed
		b.update events.dt
		if b.isAlive then
			liveBalloons.push b
		else
			b.cleanup
		end if
	end for
	// I'm not sure the balloons are always dying when they should.
	globals.balloons = liveBalloons
	
	playQuarterNote
	playHalfNote
	playChord
	
	flip
end function

ripples = []
balloons = []

sunsetImage = generateSunset

Display.text.clear
Display.background = new PixelDisplay
Display.background.install 7
Display.background.drawImage generateWater, 0, 0

// events.eventLoop.doAfter 0, @generateBalloon

canon.playForever = false
canon.totalDurationSeconds = 60 * 60
canon.endTime = time + canon.totalDurationSeconds
canon.nextChordTime = time + 3
canon.nextHalfTime = time + 3
canon.nextNoteTime = time + 3

startTime = time

events.eventLoop.run

display(7).clear
gfx.clear
flip
gfx.clear
display(4).clear
text.clear

reset
