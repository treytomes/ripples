// Pachelbel's Loose Canon
// Start from Pachelbel's chord progressions, then walk them randomly.

// Useful chord plotter: https://www.solfej.io/chords/a-major

import "importUtil"
ensureImport "events"

bpm = 100
bps = bpm / 60
spb = 1 / bps

OCTAVE_SIZE = 12
baseNoteForOctave = function(octaveNumber)
    return (octaveNumber + 1) * OCTAVE_SIZE
end function

Notes = {
    "C": 0,
    "C#": 1,
    "D": 2,
    "D#": 3,
    "E": 4,
    "F": 5,
    "F#": 6,
    "G": 7,
    "G#": 8,
    "A": 9,
    "A#": 10,
    "B": 11,
}

Chords = {
    "A": ["A", "C#", "E"],
    "Bm": ["B", "D", "F#"],
    "C": ["C", "E", "G"],
    "D": ["D", "F#", "A"],
    "E": ["E", "G#", "B"],
    "F#m": ["F#", "A", "C#"],
    "G": ["G", "B", "D"],
}

dur8 = spb / 2
dur4 = spb
dur2 = spb * 2
dur1 = spb * 4

// The triangle does a better job of hiding inconsistencies in the tune than the sine.
waveform = Sound.triangleWave
volumeEnvelope = [0, 1, 1, 1, 1, 1, 1, 0]

chordPlayer = []
for n in range(0, 2)
    i = new Sound
    i.init spb, 0, volumeEnvelope.times(0.25), waveform
    chordPlayer.push i
end for

halfNotePlayer = new Sound
halfNotePlayer.init spb, 0, volumeEnvelope.times(0.5), waveform

notePlayer = new Sound
notePlayer.init spb, 0, volumeEnvelope.times(0.125), waveform
notePlayer.init spb, 0, volumeEnvelope, waveform

playChord = function(octave, chordName, duration)
    chord = Chords[chordName]
    baseNoteNumber = baseNoteForOctave(octave)
    for n in range(0, chord.len - 1)
        noteName = chord[n]
        noteNumber = baseNoteNumber + Notes[noteName]

        chordPlayer[n].freq = noteFreq(noteNumber)
        chordPlayer[n].duration = duration
        chordPlayer[n].play
        // print "" + noteName + ", " + noteNumber + ", " + noteFreq(noteNumber)
    end for
end function

playHalfNote = function(octave, noteName, duration)
    baseNoteNumber = baseNoteForOctave(octave)
    noteNumber = baseNoteNumber + Notes[noteName]
    halfNotePlayer.freq = noteFreq(noteNumber)
    halfNotePlayer.duration = duration
    halfNotePlayer.play
end function


// Middle C = C4
// (4 + 1) * 12 = 5 * 12 = 60
playNote = function(octave, noteName, duration)
    baseNoteNumber = baseNoteForOctave(octave)
    noteNumber = baseNoteNumber + Notes[noteName]
    notePlayer.freq = noteFreq(noteNumber)
    notePlayer.duration = duration
    notePlayer.play
end function

song = [
    [ 4, "D", dur1 ],
    [ 4, "A", dur1 ],
    [ 4, "Bm", dur1 ],
    [ 4, "F#m", dur1 ],
    [ 4, "G", dur1 ],
    [ 4, "D", dur1 ],
    [ 4, "G", dur1 ],
    [ 4, "A", dur1 ],
]

nextChordTime = time
nextHalfTime = time
nextNoteTime = time
songIndex = 0
halfIndex = 0
noteIndex = 0

iteration = 1 + 8

totalDurationSeconds = 60
endTime = time + totalDurationSeconds
isDone = false
playForever = false

text.clear
while not isDone
    text.row = 1
    text.colume = 5
    print "Remaining time: " + (endTime - time)

    if (iteration % 5 == 0) and time >= nextNoteTime then
        octave = song[songIndex][0] + 2
        chordName = song[songIndex][1]
        chord = Chords[chordName]
        noteName = chord[noteIndex]
        duration = song[songIndex][2] / 4

        playNote(octave, noteName, duration)

        nextNoteTime = time + duration
        
        // Allow the high notes to walk randomly.
        delta = floor(rnd * 2)
        if delta == 0 then delta = -1
        noteIndex = noteIndex + delta

        if noteIndex >= chord.len then noteIndex = 0
        if noteIndex < 0 then noteIndex = chord.len - 1
    end if

    if (iteration % 3 == 0) and time >= nextHalfTime then
        octave = song[songIndex][0] + 1
        chordName = song[songIndex][1]
        chord = Chords[chordName]
        duration = song[songIndex][2] / 2
        
        // Allow the middle notes to walk randomly.
        delta = floor(rnd * 2)
        if delta == 0 then delta = -1
        halfIndex = halfIndex + delta
        if halfIndex >= chord.len then halfIndex = 0
        if halfIndex < 0 then halfIndex = chord.len - 1
        noteName = chord[halfIndex]

        playHalfNote(octave, noteName, duration)

        nextHalfTime = time + duration
    end if

    // The bass chords really need to walk sequentially.
	if time >= nextChordTime then
        octave = song[songIndex][0]
        chordName = song[songIndex][1]
        duration = song[songIndex][2]

        playChord(octave, chordName, duration)

        nextChordTime = time + duration

        delta = 1 // floor(rnd * 2)
        if delta == 0 then delta = -1
        songIndex += delta

        if songIndex >= song.len then
            songIndex = 0
            iteration += 1

            if time >= endTime and not playForever then isDone = true
        end if
        // if songIndex < 0 then songIndex = song.len - 1
	end if
end while
