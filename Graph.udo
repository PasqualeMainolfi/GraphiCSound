
    opcode Scale, k, kkkkk
kIn, kOutMin, kOutMax, kInMin, kInMax xin
kY = (((kIn - kInMin) * (kOutMax - kOutMin)) / (kInMax - kInMin)) + kOutMin
xout(kY)
    endop


;---MODELLI DI DISTRIBUZIONE FREQUENZIALE---

    opcode FreqExp, k, iik ;distribuzione esponenziale
iMaxFreq, iN, kCount xin
iCutFreq = sr/2
ky = ((iMaxFreq/iN) * (iMaxFreq^(kCount/iN)))
if(ky > iCutFreq) then
    ky = 0
endif
ky = abs(ky)
xout(ky)
    endop

    opcode FreqLin, k, iik ;distribuzione lineare
iMaxFreq, iN, kCount xin
iFreqMin = iMaxFreq/iN
ky = ((iFreqMin + (iMaxFreq - iFreqMin)) * (kCount/(iN - 1)))
xout(ky)
    endop

    opcode FreqMel, k, iik ;distribuzione scala mel
iMaxFreq, iN, kCount xin

ia = 2595
ib = 700
iLimit = 1000

kx = iMaxFreq * ((kCount + 1)/(iN - 1))

if(kx <= iLimit) then
    ky = kx
    elseif(kx > iLimit) then
        ky = ia * log10(1 + (kx/ib))
    endif
xout(ky)
    endop

    opcode FreqLog, k, iik ;distribuzione logaritmica
iMaxFreq, iN, kCount xin
ky = iMaxFreq * (log10(kCount)/log10(iN))
xout(ky)
    endop

    opcode FreqTemp, k, iiik
iMaxFreq, iOct, iN, kCount xin
ix = iN/iOct
ky = (iMaxFreq/iN) * ((2^kCount)^(1/ix))
xout(ky)
    endop

    opcode FreqNat, k, iiik
iMaxFreq, iOct, iN, kCount xin
ix = iN/iOct
ky = ((iMaxFreq/iN) * kCount)/((2^kCount)^(1/ix)) ;discendente
xout(ky)
    endop

    opcode FreqPit, k, iik
iMaxFreq, iN, kCount xin
iRatio = 3/2
iFreqMin = (iMaxFreq)/iN
iPowMax = floor(log(iMaxFreq/iFreqMin)/log(iRatio)) ;in modo da trovare potenza in relazione alla massima frequenza
kPow = Scale:k(kCount, 1, iPowMax, 0, iN)
ky = iFreqMin * ((iRatio)^kPow)
xout(ky)
    endop

;--------------------------------------


    opcode DistribuzioneFrequenze, k, iikiip ;per i modelli di distribuzione frequenziale
iMaxFreq, iN, kCount, iDur, iMode, iOct xin

if(iMode == 0) then
    kFreq = FreqLin(iMaxFreq, iN, kCount) * iDur ;distribuzione lineare delle frequenze: restituisce fedele rappresentazione spettrografica dell'immagine caricata
    elseif(iMode == 1) then
        kFreq = FreqExp(iMaxFreq, iN, kCount) * iDur
    elseif(iMode == 2) then
        kFreq = FreqLog(iMaxFreq, iN, kCount) * iDur
    elseif(iMode == 3) then
        kFreq = FreqMel(iMaxFreq, iN, kCount) * iDur
    elseif(iMode == 4) then
        kFreq = FreqTemp(iMaxFreq, iOct, iN, kCount) * iDur
    elseif(iMode == 5) then
        kFreq = FreqNat(iMaxFreq, iOct, iN, kCount) * iDur
    elseif(iMode == 6) then
        kFreq = FreqPit(iMaxFreq, iN, kCount) * iDur
    endif

xout(kFreq)
    endop


    opcode SpectPlot, aa, Siiiiiiiip
Simage, iFreqSup, iDistrModel, iPortAmp, iPan, iPortPan, iDur, iColorMode, iFun, iOct xin

/*
CONVERTE UN'IMMAGINE .PNG IN IMMAGINE SPETTROGRAFICA (using wavetable!)

Simage = stringa "nomefile.png"
iFreqSup = massima frequenza superiore
iDistrModel = modello di distribuzione frequenziale: 0 = lineare, 1 = esponenziale, 2 = logaritmica, 3 = mel, 4 = temperata, 5 = scala naturale, 6 = scala pitagorica
iPortAmp = portamento sull'ampiezza (in sec.)
iPan = 0 e 1 (0 = solo al centro, 1 = decodifica stereo)
iPortPan = portamento panning (in sec.)
iDur = durata complessiva out
iColorMode = color inversion (0 ---> black = no sound (white on black). 1 ---> white = no sound (black on white))
iFun = Function number
iOct = Divisione in ottave (valore intero, solo per scala temperata, naturale). Es. 1 = intero range una sola ottava, 2 = intero range due ottave, etc...

N.B.
    - per una fedele rappresentazione dell'immagine usare distribuzione lineare
    - usando array al posto della tabella, durate maggiori di 10" causano errore segmentation fault (segfault)
*/

img = imageload(Simage)
iW, iH imagesize img

iSampleDur = floor(iDur * sr)
iN = iSampleDur

iTabLeft = ftgen(iFun, 0, -iN, 2, 0)
iTabRight = ftgen(iFun + 1, 0, -iN, 2, 0)
iEnvAmp = ftgen(iFun + 2, 0, 16384, 20, 2)

i2pi = 2 * $M_PI

iMaxFreq = iFreqSup
iyFreq = iMaxFreq/iH

kY init 0

printf("\n", 1)

ky init iH - 1
until (ky == 0) do
    kx = 0
    until (kx == iN) do
        kred, kgreen, kblue imagegetpixel img, Scale:k(kx, 0, 1, 0, iN), Scale:k(ky, 0, 1, iH - 1, 0)
        kAmpRGB = portk(abs(iColorMode - ((kred + kgreen + kblue)/3)), iPortAmp) ;ampiezza da RGB
        kPan = portk((random:k(0, 1) + (kred + kgreen + kblue))/4, iPortPan) ;pan
        kVol = tablei:k(Scale(kx, 0, ftlen(iEnvAmp), 0, iN), iEnvAmp) * kAmpRGB ;applicazione inviluppo
        kFreq = DistribuzioneFrequenze(iMaxFreq, iH, ky, iDur, iDistrModel, iOct) ;modello distributivo delle frequenze

        if(iPan = 0) then
            kLeft = 1
            kRight = 1
            elseif(iPan = 1) then
                kLeft = sqrt(kPan)
                kRight = sqrt(1 - kPan)
            endif

        kSigL = (kVol * sin(kFreq * (i2pi/iN) * kx)) * kLeft
        kSigR = (kVol * sin(kFreq * (i2pi/iN) * kx)) * kRight
        kY_left = (kSigL + tablei:k(kx, iTabLeft))
        kY_right = (kSigR + tablei:k(kx, iTabRight))

            tablew(kY_left, kx, iTabLeft) ;scrittura in tabella canale sx
            tablew(kY_right, kx, iTabRight) ;scrittura in tabella canale dx

        kx += 1
    od
    printf("WAIT... STO CONVERTENDO L'IMMAGINE %s... \t---> progress: %d%%\r", ky + 1, Simage, int(Scale:k(ky, 0, 100, iH, 0)) + 1)
    ky -= 1
od

printf("\n", 1)
printf("FATTO! %s È STATA CONVERTITA IN IMMAGINE SONOGRAFICA\n", 1, Simage)
printf("\n", 1)

aL = tablei:a(phasor:k(1/iDur), iTabLeft, 1)
aL = aL/iH

aR = tablei:a(phasor:k(1/iDur), iTabRight, 1)
aR = aR/iH

xout(aL, aR)
    endop


;=====================================================
;=====================================================
;=====================================================

    opcode IntToRGB, kkk, ko ;converte intero in RGB
kV, iMode xin

/*
kV = intero positivo da 0 a 2^24 (24 bit)
iMode = opzionale, di default uguale a 0 per RGB. 1 = Greyscale
in uscita --> valori RGB compresi tra 0 e 255
*/

ia = 256

kred = (kV >> 16) & 255
kgreen = (kV >> 8) & 255
kblue = kV & 255

if(iMode = 0) then
    kR = kred
    kG = kgreen
    kB = kblue
    elseif(iMode = 1) then
        kR = kred/3
        kG = kgreen/3
        kB = kblue/3
    endif

xout(kR, kG, kB)
    endop


    opcode PngPlot, i, Siiiiiiiiiiii
Sfile, iWidth, iHeight, iMaxFreq, iColorMode, iPortAmp, iPortFreq, iPortEnv, iType, iFFT_size, iHop, iWindow_size, iPlot xin

iDur = filelen(Sfile)
iN = ceil(iDur * sr)

iSig = ftgen(100, 0, iN, 1, Sfile, 0, 0, 0)
ax = tablei:a(1/iDur * iN, iSig) ;non so perchè serva fare questo, so solo che funziona!

iW = iWidth
iH = iHeight

imgNew = imagecreate(iW, iH)

kj init 0
while (kj <= iN) do
    aIn = tablei:k(kj, iSig)
    kw_ = Scale:k(kj, 0, iW, 0, iN)
    kw = Scale:k(kw_, 0, 1, 0, iW)
    kSig = downsamp(aIn)
    fSig = pvsanal(a(kSig), iFFT_size, iHop, iWindow_size, 1)
    kFreq, kAmp pvspitch fSig, 1/sr
    kf, ka ptrack a(kSig), iFFT_size


        if(iType = 0) then
            kh = portk(Scale(kf, 1, 0, iMaxFreq/iH, iMaxFreq), iPortFreq)
            ;kV = (10^(ka/20)) ;conversione da dB a lineare (antilogaritmo)
            kV = sqrt(kSig^2) ;valore assoluto
            kO = sqrt(kSig^2) * sin(kf)
            elseif(iType = 1) then
                kh = portk(Scale(kFreq, 1, 0, iMaxFreq/iH, iMaxFreq), iPortFreq)
                kV = kAmp
                kO = kAmp * sin(kf)
            endif

    kred, kgreen, kblue IntToRGB portk(kV, iPortAmp) * 2^24, iColorMode
    kR = abs(iColorMode - Scale(kred, 0, 1, 0, 255))
    kG = abs(iColorMode - Scale(kgreen, 0, 1, 0, 255))
    kB = abs(iColorMode - Scale(kblue, 0, 1, 0, 255))

        if(iPlot = 0) then
            imagesetpixel(imgNew, kw, kh, kR, kG, kB)
            elseif(iPlot = 1) then
                imagesetpixel(imgNew, kw, portk(Scale(kV, 1, 0, 0, 1), iPortEnv), 1, 1, 1)
                elseif(iPlot = 2) then
                    imagesetpixel(imgNew, kw, portk(Scale(kO, 1, 0, -1, 1), iPortEnv), kR, kG, kB)
                    elseif(iPlot = 3) then
                        imagesetpixel(imgNew, kw, kh, kR, kG, kB)
                        imagesetpixel(imgNew, kw, portk(Scale(kV, 1, 0, 0, 1), iPortEnv), 1, 1, 1)
                    endif

    kj += 1
od

xout(imgNew)
    endop
