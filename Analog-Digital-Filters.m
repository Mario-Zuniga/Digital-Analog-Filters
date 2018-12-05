%% Sección Analógica
% 1. Escoger un archivo en formato WAV, no comprimido. Leer 10 segundos, 
% convertir el audio a mono,  x=(xizq+xder)/2.
% Tomamos la información
filename='Audio.wav';
clear y Fs
[y,Fs]=audioread('Audio.wav');

% Guardamos la variable de información
info=audioinfo(filename);

% Guardamos un tiempo para 10 segundos de muestra
samples=[1,10*Fs];
clear y Fs

% Leemos 10 segundos de la cancion
[y Fs]=audioread(filename,samples);

% Guardamos las muestras
sample_10_seconds = y;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Filtrar la señal a 15 kHz. 
% Datos para el filtro
o = 100;             % Orden de filtro
m = [1 1 0 0];       % Magnitud
B = 15000;           %Ancho de banda Hz
Fc = B/(Fs/2);       %Frecuencia de corte de 15kHz

Vc = [0 Fc Fc 1];    % 15,000 Hz


% Creacion del filtro
FiltroPB_15 = fir2(o, Vc, m);

% Se aplica la convolucion del filtro con la señal de audio
fir_15 = conv(y, FiltroPB_15);    % Convolucion con filtro 15,000 Hz


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Normalizar la potencia de la señal filtrada a un watt. 
potencia = 1;       % Valor para Watt

% Obtenemos su potencia
P_f = (1/length(fir_15)) * (fir_15'*fir_15);

% Ajustamos la señal de potencia para que sea la deseada
signal = (fir_15/sqrt(P_f)) * sqrt(potencia);

% Comprobamos que sea la correcta
P_f = (1/length(signal)) * (signal'*signal);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Encontrar la potencia del ruido a la salida del filtro receptor, 
% para N0 = 1/(15000*100:0.3:3). 
N0 = 1./(15000*10.^(0:0.3:3));

% Encontrar la potencia del ruido Pn a la salida del filtro
Pn = N0 * B;


% Encontrar el SNR, y tomar nota de este valor. 
for x = 1 : 11
    SNR_an(x) = 1/Pn(x);
end

% Convertimos el SNR a dB
SNR_an_dB = 10*log10(SNR_an);


% El siguiente ciclo creara un vector de ruido que sera añadido a la
% señal de audio, posteriormente será escrito en un archivo de audio
for x = 1 : numel(N0)
    % Creamos el vector de ruido con la potencia N0
    Noise = sqrt(Pn(x)) * rand(numel(fir_15), 1);
    
    % Añadimos el ruido a la señal de audio
    y1 = fir_15 + Noise;
    
    % Para estabilizar la señal lo dividimos por el valor absoluto
    % mas alto de la señal
    y1 = y1/max(abs(y1));
   
    % Escribimos el archivo de audio
    audiowrite(['Audio_analogico_N',num2str(x),'.wav'], y1, Fs);
end


%% Sección digital

% 1. Tomar el mismo archivo WAV que en la parte analógica, leer 10 
% segundos, convertirlo a mono. 
% Tomamos la información
filename='Audio.wav';
clear y Fs
[y,Fs]=audioread('Audio.wav');

% Guardamos la variable de información
info=audioinfo(filename);

% Guardamos un tiempo para 10 segundos de muestra
samples=[1,10*Fs];
clear y Fs

% Leemos 10 segundos de la cancion
[y Fs]=audioread(filename,samples);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Convertir las muestras de audio a un vector de bits. 
bx = 16;
% Calculamos el offset
offset = (2^bx-1)/2;

% Se le añade el offset a los valores redondeados de las muestras
convertion = round(sample_10_seconds*offset+offset);


% Convertimos la muestra a bits
b = de2bi(convertion, bx,'left-msb'); 
b = b';

bits = b(:);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%3. Sabiendo que contamos con un ancho de banda B = 15 kHz, 
%calcular la tasa de bit Rb máxima y la energía de  cada pulso transmitido. 
Bw = 15000;
beta = 0.25;

% Aplicamos la siguiente fórmula, el valor de beta
% es tomado del punto 4
Rb = (2 * Bw) / (1 + beta);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%4. Diseñar el pulso SRRC con ? = 0.25 a utilizar. 
% Suponga D = 6 y Fs = 48000 y B = 15 kHz; ¿Cuál es el valor de Rb  elegido? 
% Coseno Alzado Square_Root
fs = 48000;
Tp = 1/Rb;
D = 6;
e = 1/Rb;
type = 'srrc';
Ts = 1/fs;
mp = fs/Rb;

% Los valores de Rb y beta son del punto 3
p = rcpulse(beta, D, Tp, Ts, type, e);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Genere el tren de pulsos utilizando un Código de línea 
% de su elección y el pulso base diseñado. 
% Generamos un tren de pulsos Bipolar NRZ
% ya que es el que usamos en tareas anteriores con exito

% Guardamos los valores originales en una variable
% respaldo
bits_digital = bits;

% Cambiamos los bits 0 a 1 y los convertimos a vector
bits(bits==0) = -1;
s = zeros(1, (numel(bits) - 1) * mp + 1); %Generar el vector
s(1:mp:end) = bits;

% Hacemos la convolución
signal = conv(s,p);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. Normalice el tren de pulsos para que tenga 
% potencia unitaria (solamente así se podrá comparar). 
% La potencia del tren de pulsos deberá quedar en 1 W
% igual que la señal analógica

% La variable 'potencia' fue declarada en la sección 
% analógica
potencia = 1;

% Obtenemos su potencia
P_dig_f = (signal*signal')/numel(signal);

% Ajustamos la señal de potencia para que sea la deseada
signal = (signal/sqrt(P_dig_f)) * sqrt(potencia);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculamos valores N0 digitales
N0_dig = 1./(15000*10.^(0:0.3:3));

% Calculamos las potencias de N0
Pn_dig = N0_dig * Bw;

% Encontrar el SNR, y tomar nota de este valor. 
for x = 1 : 11
    SNR_dig(x) = 1/Pn_dig(x);
end

% Convertimos el SNR a dB
SNR_dig_dB = 10*log10(SNR_dig);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datos para el filtro
o = 100;             % Orden de filtro
m = [1 1 0 0];       % Magnitud
B = 15000;           %Ancho de banda Hz
Fc = B/(fs/2);       %Frecuencia de corte de 15kHz

Vc = [0 Fc Fc 1];    % 15,000 Hz
    
% Creacion del filtro
FiltroPB_15 = fir2(o, Vc, m);

% El siguiente ciclo genera los vectores de ruido que seran añadidos a la
% señal, posteriormente pasara por un filtro pasa-bajas y un filtro match
% (acoplado), seran muestreadas y transformadas para crear archivos
% de audio
for x = 1 : 11
   
    % Creamos el vector de ruido con la potencia deseada
    Noise_dig = sqrt(Pn_dig(x)) * randn(1, numel(signal));

    % Añadimos el ruido a la señal
    signal_plus_noise = signal + Noise_dig;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Filtramos las señales con el filtro pasa bajas
    fir_dig = conv(signal_plus_noise, FiltroPB_15);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 9. Pase la salida del filtro LPF del receptor por el filtro acoplado  
    % y realice el muestreo a la salida del filtro receptor como se 
    % muestra en la fig. 2. 
    
    % Pasamos la señal por el filtro acoplado
    match_dig = conv(fir_dig, p);
    
    % Comenzamos a hacer el muestreo tomando los offsets de los filtros
    % raised cosine y el pasabajas
    y_out = match_dig(63:mp:end);
    y_out = y_out(1:numel(bits));

    % Convertimos los valores mayores a 0 en 1 y los menores a 0 en -1
    sym_RX = sign(y_out);

    % Creamos un vector del tamaño de sym_RX
    bits_RX = ones(1,numel(sym_RX));
    
    % Verificamos si existen valores -1 en sym_RX, de ser el caso
    % en el vector bits_RX se pondrá 0 en esas posiciones
    bits_RX(sym_RX == -1) = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Tomamos el vector y lo convertimos en una matriz, tomando 16
    % bits para su transformacion
    br = vec2mat(bits_RX, 16);

    % Convertimos el vector a una señal analogica
    ar = bi2de(br, 'left-msb');

    % Restamos el offset de la señal resultante
    y_dig = ar-offset;
    
    % Mantenemos la señal resultado en un rango entre -1 y 1 al dividir
    % entre el valor absoluto maximo de la misma señal
    y_dig = y_dig/max(abs(y_dig));

    % Escribimos el archivo de audio
    audiowrite(['Audio_digital_N',num2str(x),'.wav'],y_dig,Fs);
    
end
