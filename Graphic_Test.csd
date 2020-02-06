<CsoundSynthesizer>
<CsOptions>
;-o dac
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 1
nchnls = 2
0dbfs = 1


#include "Graph.udo"

seed(0)

  instr 1 ; SpectPlot (Spectrographic Image)

/*
SpectPlot(Simage, iFreqSup, iDistrModel, iPort, iDur, iColorMode, iFun, iOct)

Simage = stringa "nomefile.png"
iFreqSup = limite frequenziale superiore
iDistrModel = modello di distribuzione frequenziale: 0 = lineare, 1 = esponenziale, 2 = logaritmica, 3 = mel, 4 = temperata, 5 = scala naturale, 6 = scala pitagorica
iSogliaAmpiezza = soglia sotto cui escludere ampiezze. Tutto ciò al di sotto viene escluso
iPortAmp = portamento sull'ampiezza (in sec.)
iPan = 0 e 1 (0 = solo al centro, 1 = decodifica stereo)
iPortPan = portamento panning (in sec.)
iDur = durata complessiva segnale in uscita
iColorMode = color inversion (0 ---> black = no sound (white on black). 1 ---> white = no sound (black on white))
iOct = default 1. Numero di ottave (valore intero, opzionale solo per scala temperata e naturale). Es. 1 = intero range una sola ottava, 2 = intero range due ottave, etc...

N.B.
    - per una fedele rappresentazione dell'immagine usare distribuzione lineare
    - usando array al posto della tabella, durate maggiori di 10" causano errore segmentation fault (segfault)
    - seed(0) per la componente casuale panning
*/

Simg = "img_kand_2.png"
iMaxFreq = 1200
iDistrModel = 6
iS_amp = .05
iPortAmp = .1
iPan = 1
iPortPan = .01
iDur = p3
iColorMode = 1
iOct = 5

aL, aR SpectPlot Simg, iMaxFreq, iDistrModel, iS_amp, iPortAmp, iPan, iPortPan, iDur, iColorMode, iOct
aL = aL * 5
aR = aR * 5

  outs(aL, aR)

  endin



;---from audio to image---

gimg init 0

  instr 2 ; PngPlot(Converte un segnale immagine .png "pseudospettrografica")

/*

PngPlot(Sfile, iWidth, iHeight)

asse x = tempo
asse y = frequenza e ampiezza

Sfile = "nomeImmagineCreata.png"
iWidth = larghezza in pixel immagine
iHeight = altezza in pixel immagine
iMaxFreq = massima frequenza rappresentabile
iColorMode = 0 RGB 1 B/W
iPortAmp = portamento sull'ampiezza tracciata (a valori molto piccoli poco smusso e viceversa)
iPortFreq = portamento sul frequenza tracciata (a valori molto piccoli poco smusso e viceversa)
iPortEnv = portamento sul disegno del inviluppo (a valori molto piccoli poco smusso e viceversa)
iType = 0 ---> ptrack (vedi csound manual). 1 ---> phaseVocoder
iFFT_size = FFT size
iHop = overlapping
iWindow_size = window size
iPlot = sceglie cosa plottare: 0 = spettro in frequenza, 1 = ampiezza, 2 = oscilloscopio, 3 = freq + ampiezza

N.B.
  - solo segnali mono

*/

SorgenteAudio = "Src1.wav"
iWidth = 4096
iHeight = 2048
iMaxFreq = sr/2
iColorMode = 0
iPortAmp = .00001
iPortFreq = 0
iPortEnv = .0001
iType = 0
iFFT_size = 64
iHop = iFFT_size/2
iWindow_size = iFFT_size
iPlot = 2

gimg = PngPlot(SorgenteAudio, iWidth, iHeight, iMaxFreq, iColorMode, iPortAmp, iPortFreq, iPortEnv, iType, iFFT_size, iHop, iWindow_size, iPlot)

  endin

  instr 3
imagesave(gimg, "prova.png")
  endin



</CsInstruments>
<CsScore>

;i 1 0 120
i 2 0 1
i 3 2 1

</CsScore>
</CsoundSynthesizer>
