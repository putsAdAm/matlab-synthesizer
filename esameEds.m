% SINTETIZZATORE di AMOROSINI ADRIANO
clc; clearvars; close all;

% PARAMETRI
Fs = 16000;
ottavaCanto = 4;
ottavaChords = 3;
tipoCanto = 4;
tipoChords = 5; 
volumeMelodia = 0.5;
volumeChords = 0.5;
Metronomo = 60;         %Metronomo alla semiminima
tempo = 60 / Metronomo;

% Melodia del canto (NaN rappresenta una pausa)
melodia = [
    NaN, (2*tempo)/3;
    2, tempo/3;
    2, tempo/3;
    0, tempo/3;
    10, tempo/3;
    0, tempo/4;
    10, tempo/12;
    7, (5*tempo)/3;
    0, (3*tempo)/2;
    10, tempo/6;
    10, tempo/4;
    9, tempo/12;
    10, 2*tempo;
];

% Accordi: Sol(I°), Do(IV°), Re(V°), Sol(I°)
accordi = [10; 3; 5; 10];
durataAccordo = 2*tempo;

% Costruisco l'accompagnamento, creando i 4 accordi, applicandoci
% successivamente l'effetto ADSR a ciascuno e concatendandoli
accompagnamento = [];
for i = 1:length(accordi)
    acc = creaAccordo(accordi(i), Fs, durataAccordo, ottavaChords, tipoChords, volumeChords);
    acc = effettoADSR(Fs, acc, durataAccordo, 0.05, 0.05, 0.9, 0.5); % ADSR
    accompagnamento = [accompagnamento, acc];
end

% Creo la melodia del canto
melodiaAudio = creaMelodia(melodia, Fs, ottavaCanto, tipoCanto, volumeMelodia, tempo);

%Zero-padding
len = max(length(melodiaAudio), length(accompagnamento));
melodiaAudio(end+1:len) = 0;
accompagnamento(end+1:len) = 0;

% Risultato finale
output = melodiaAudio + accompagnamento;
sound(output, Fs);


function [mel] = creaMelodia(melodia, Fs, ottava, tipo, volume, tempo)
    mel = [];
    for i = 1:size(melodia, 1)
        nota = melodia(i, 1);
        dur = melodia(i, 2);
        if isnan(nota)
            suono = 0 * 0:1/Fs:dur;
        else
            suono = volume * creaSuono(Fs, dur, nota, ottava, tipo);
            if dur >= tempo
                suono = effettoADSR(Fs, suono, dur, 0.05, 0.05, 0.9, 0.6);
            else
                suono = effettoADSR(Fs, suono, dur, 0.1, 0.1, 0.25, 0.9);
            end
        end
        mel = [mel, suono];
    end
end

function [suono] = creaSuono(Fs, dur, nota, ottava, tipo)
    frif = 440;
    if nota <= 2
        freqSuono = (2^(nota/12)*frif) * 2^(ottava - 4);
    else
        freqSuono = (2^(nota/12)*frif) * 2^(ottava - 5);
    end
    t = 0:1/Fs:dur;
    switch tipo
        case 1
            suono = sin(2*pi*freqSuono*t);
        case 2
            suono = square(2*pi*freqSuono*t);
        case 3
            suono = sawtooth(2*pi*freqSuono*t);
        case 4
                violino = [0.791249 1 0.215249 0.439067 0.505303 0.275502 0.201708 0.267734  ... 
                    0.109982 0.0751184 0.0359502 0.0862367 0.0519543 0.0391827 0.0239706 0.0218566];
            suono = violino(1) * sin(2*pi*freqSuono*t);
            for i = 2:length(violino)
                suono = suono + violino(i)*sin(2*pi*i*freqSuono*t);
            end
        case 5
            piano = [0.79457 1 0.325765 0.0701682 0.0939638 0.0396478 0.0610916];
            suono = piano(1) * sin(2*pi*freqSuono*t);
            for i = 2:length(piano)
                suono = suono + piano(i)*sin(2*pi*i*freqSuono*t);
            end
    end
    suono = suono/max(abs(suono));
end

function [accordo] = creaAccordo(tonica, Fs, dur, ottava, tipo, volume)
    % Distanza in semitoni dalla fondamentale
    intervalli = [0, 4, 7];
    %Note effettive
    gradi = mod(tonica + intervalli, 12);
    accordo = 0 * 0:1/Fs:dur;
    for i = 1:3
        suono = creaSuono(Fs, dur, gradi(i), ottava, tipo);
        accordo = accordo + suono;
    end
    accordo = volume * accordo;
end


function [outSuono] = effettoADSR(Fs, suono, dur, ta, td, tr, as)
    t1 = round(ta * dur * Fs);
    t2 = round(t1 + td * dur * Fs);
    t3 = round(length(suono) - tr * dur * Fs);

    E = zeros(1, length(suono));
    E(1:t1) = linspace(0, 1, t1);
    E(t1+1:t2) = linspace(1, as, t2 - t1);
    E(t2+1:t3) = as;
    E(t3+1:end) = linspace(as, 0, length(suono) - t3);

    outSuono = suono .* E;
end
