%h5gRateMatchLDPC 5G LDPC rate matching
%   OUT = h5gRateMatchLDPC(...) rate matches the matrix input data to
%   create the vector OUT. This function includes the stages of bit
%   selection, interleaving defined for LDPC encoded data and code block
%   segmentation (see TS 38.212 Subclauses 5.4.2 and 5.5). The function
%   does not support code block group (re-)transmissions.
%
%   OUT = h5gRateMatchLDPC(IN,OUTLEN,RV,CHS) rate matches the input data IN
%   to create vector OUT of length OUTLEN. The input data is a matrix, each
%   column of which is assumed to be a code block. In the case of the
%   number of columns in IN >= 2, each column is rate matched separately
%   and the results are concatenated into the single output vector OUT. The
%   redundancy version (RV) of the output is controlled by the RV parameter
%   (0,1,2,3). The CHS structure should contain the following fields:
%   NBG        - Base graph number (1,2)
%   Modulation - Modulation format ('BPSK','QPSK','16QAM','64QAM','256QAM')
%   NLayers    - Total number of transmission layers associated with the
%                transport block(s) (1...8) y UPLINK (1...4).
%   TBSLBRM    - Optional. Transport block size used to configure the soft
%                buffer size for limited buffer rate matching. It is
%                assumed no limit is placed on the number of soft bits,
%                when the field is not provided
%
%   Example:
%   % The example below shows the rate matching of two LDPC encoded code
%   % blocks of length 2000 to a vector of length 5000. The selected 
%   % parameters are: the base graph number is 1, the RV is set to 0, QPSK
%   % modulation is used and the number of layers is 1.
%   
%   % Select channel parameters for rate recovery
chs.NBG = 1;
chs.rv = 1;
chs.Modulation = 'QPSK';
chs.NLayers = 1;
% 

encoded = ones(1,6600);
encoded(1,150:1:359) = 0;
encoded(1,1350:1:1499) = 0;
encoded(1,3800:1:4099) = 0;
encoded(1,5600:1:6099) = 0;

%encoded(6:1:6000,1) = 0;
outlen = 6600;
ratematched = h5gRateMatchLDPC(encoded,outlen,chs.rv,chs);
fila_sol=reshape(ratematched,[1,6600]);
size(ratematched)

%trblklen = 4000;
%raterecovered = h5gRateRecoverLDPC(ratematched,trblklen,chs.rv,chs);
%size(raterecovered)
%
%   See also h5gRateRecoverLDPC, lteRateMatchTurbo.

% Copyright 2017-2018 The MathWorks, Inc.

function out = h5gRateMatchLDPC(in,outlen,rv,chs)

    in=reshape(in,[3300 2]);
    
    % Ouput empty if the input is empty or the rate matching output length
    % is 0
    if isempty(in) || ~outlen
        out = zeros(0,1,class(in));
        return;
    end

    % Validate the input base graph number
    if ~(chs.NBG == 1 || chs.NBG == 2)
        error('lte:error','The input base graph category number (%d) should be either 1 or 2.',chs.NBG);
    end
    
    % Get modulation order
    if strcmpi(chs.Modulation,'BPSK')
        Qm = 1;
    elseif strcmpi(chs.Modulation,'QPSK')
        Qm = 2;
    elseif strcmpi(chs.Modulation,'16QAM')
        Qm = 4;
    elseif strcmpi(chs.Modulation,'64QAM')
        Qm = 6;
    elseif strcmpi(chs.Modulation,'256QAM')
        Qm = 8;
    end
    
    % Get code block soft buffer size
    N = size(in, 1);
    C = size(in, 2);
    
    %size(in)
    if isfield(chs,'TBSLBRM')
        Nref = floor(3*chs.TBSLBRM/4);
        Ncb = min(N,Nref);
    else % No limit on buffer size
        Ncb = N; 
    end

    % Get starting position in circulr buffer
    if chs.NBG == 1
        Zc = N/66;
        if rv == 0
            k0 = 0;
        elseif rv == 1
            k0 = floor(17*Ncb/(66*Zc))*Zc;
        elseif rv == 2
            k0 = floor(33*Ncb/(66*Zc))*Zc;
        elseif rv == 3
            k0 = floor(56*Ncb/(66*Zc))*Zc;
        end
    else
        Zc = N/50;
        if rv == 0
            k0 = 0;
        elseif rv == 1
            k0 = floor(13*Ncb/(50*Zc))*Zc;
        elseif rv == 2
            k0 = floor(25*Ncb/(50*Zc))*Zc;
        elseif rv == 3
            k0 = floor(43*Ncb/(50*Zc))*Zc;
        end
    end
    
    % Validate the input data size
    if fix(Zc) ~= Zc
        if chs.NBG == 1
            Ncw = 66;
        else
            Ncw = 50;
        end
        error('lte:error','The number of rows in the input data matrix (%d) should be a multiple integer of %d (for base graph %d).', N, Ncw, chs.NBG);
    end
    
    % Get rate matching output for all code blocks and perform code block
    % concatenation according to 38.212 5.4.2 and 5.5
    out = [];
    for r = 0:C-1
        if r <= C-mod(outlen/(chs.NLayers*Qm),C)-1
            E = chs.NLayers*Qm*floor(outlen/(chs.NLayers*Qm*C));
        else
            E = chs.NLayers*Qm*ceil(outlen/(chs.NLayers*Qm*C));
        end
        out = [out; cbsRateMatch(in(:,r+1),E,k0,Ncb,Qm)]; %#okARGOW
        %in(:,r+1)
    end
end

% Rate matching for a single code block segment according to 38.212 5.4.2
function e = cbsRateMatch(d,E,k0,Ncb,Qm)

    % Perform bit selection according to 38.212 5.4.2.1
    k = 0;
    j = 0;
    e = zeros(E,1,class(d));
    while k < E
        if d(mod(k0+j,Ncb)+1) ~= -1 % <NULL> filler bits
            e(k+1) = d(mod(k0+j,Ncb)+1);
            k = k+1;
        end
        j = j+1;
    end
    
    % Perform bit interleaving according to 38.212 5.4.2.2
    e = reshape(e,E/Qm,Qm);
    e = e.';
    e = e(:);
    
end

function out = h5gRateRecoverLDPC(in,trblklen,rv,chs,varargin)
    
    % Validate the number of inputs
    narginchk(4, 5);
    
    % Ouput empty if the input is empty or transport block size is 0
    if isempty(in) || ~trblklen
        out = zeros(0,1,class(in));
        return;
    end
    
    % Get buffers for HARQ combining
    if nargin == 4
        cbsbuffers = [];
    else
        cbsbuffers = varargin{1};
    end

    % Validate the input base graph number
    if ~(chs.NBG == 1 || chs.NBG == 2)
        error('lte:error','The input base graph category number (%d) should be either 1 or 2.',chs.NBG);
    end
    
    % Get transport block size after CRC attachement according to 38.212
    % 6.2.1 and 7.2.1
    if trblklen > 3824
        B = trblklen + 24;
    else
        B = trblklen + 16;
    end
    
    % Get code block segementation parameters
    chsinfo = getCBSParams(B,chs.NBG);
    C = chsinfo.C;
    zc = chsinfo.ZC;
    N = chsinfo.N;

    % Get code block soft buffer size
    if isfield(chs,'TBSLBRM')
        Nref = floor(3*chs.TBSLBRM/4);
        Ncb = min(N,Nref);
    else % No limit on buffer size
        Ncb = N; 
    end

    % Get modulation order
    if strcmpi(chs.Modulation,'BPSK')
        Qm = 1;
    elseif strcmpi(chs.Modulation,'QPSK')
        Qm = 2;
    elseif strcmpi(chs.Modulation,'16QAM')
        Qm = 4;
    elseif strcmpi(chs.Modulation,'64QAM')
        Qm = 6;
    elseif strcmpi(chs.Modulation,'256QAM')
        Qm = 8;
    end
    
    % Get starting position in circular buffer
    if chs.NBG == 1
        if rv == 0
            k0 = 0;
        elseif rv == 1
            k0 = floor(17*Ncb/(66*zc))*zc;
        elseif rv == 2
            k0 = floor(33*Ncb/(66*zc))*zc;
        elseif rv == 3
            k0 = floor(56*Ncb/(66*zc))*zc;
        end
    else
        if rv == 0
            k0 = 0;
        elseif rv == 1
            k0 = floor(13*Ncb/(50*zc))*zc;
        elseif rv == 2
            k0 = floor(25*Ncb/(50*zc))*zc;
        elseif rv == 3
            k0 = floor(43*Ncb/(50*zc))*zc;
        end
    end

    G = length(in);
    gIdx = 1;
    out = zeros(N,C);
    for r = 0:C-1
        if r <= C-mod(G/(chs.NLayers*Qm),C)-1
            E = chs.NLayers*Qm*floor(G/(chs.NLayers*Qm*C));
        else
            E = chs.NLayers*Qm*ceil(G/(chs.NLayers*Qm*C));
        end
        deconcatenated = in(gIdx:gIdx+E-1);
        gIdx = gIdx + E;
        if isempty(cbsbuffers)
            out(:,r+1) = cbsRateRecover(chsinfo,deconcatenated,k0,Ncb,Qm,[]);
        else
            out(:,r+1) = cbsRateRecover(chsinfo,deconcatenated,k0,Ncb,Qm,cbsbuffers(:,r+1));
        end
    end
    
end

% Rate recovery for a single code block segment
function out = cbsRateRecover(chsinfo,in,k0,Ncb,Qm,cbsbuffer)

    % Perform bit de-interleaving according to 38.212 5.4.2.2
    E = length(in);
    in = reshape(in,Qm,E/Qm);
    in = in.';
    in = in(:);

    % Pruncture systematic bits
    K = chsinfo.K - 2*chsinfo.ZC;
    Kd = chsinfo.Kd - 2*chsinfo.ZC;
    
    % Perform reverse of bit selection according to 38.212 5.4.2.1
    k = 0;
    j = 0;
    indices = zeros(E,1);
    while k < E
        idx = mod(k0+j, Ncb);
        if ~(idx >= Kd && idx < K) % Avoid <NULL> filler bits
            indices(k+1) = idx+1;
            k = k+1;
        end
        j = j+1;
    end
    
    % Recover circular buffer
    out = zeros(chsinfo.N,1);
    
    % Filler bits are treated as 0 bits when perform encoding, 0 bits
    % corresponding to Inf in received soft bits, this step improves
    % error-correction performance in the LDPC decoder
    out(Kd+1:K) = Inf;
    
    for n = 1:E
        out(indices(n)) = out(indices(n)) + in(n);
    end
    
    % HARQ soft-combining
    if ~isempty(cbsbuffer)
        if size(cbsbuffer,1) ~= chsinfo.N
            error('lte:error','If the CBSBuffers soft data input is not empty then it should have the same dimensions as this function will output.');
        else
            out = out + cbsbuffer;
        end
    end
    
end

function info = getCBSParams(B,nbg)

    % Get the maximum code block size
    if nbg == 1
        Kcb = 8448;
    else
        Kcb = 3840;
    end
    
    % Get number of code blocks and length of CB-CRC coded block
    if B <= Kcb
        C = 1;
        Bd = B;
    else
        L = 24; % Length of the CRC bits attached to each code block
        C = ceil(B/(Kcb-L));
        Bd = B+C*L;
    end
    
    % Obtain and verify the number of bits per code block (excluding CB-CRC
    % bits)
    cbz = B/C;
    if fix(cbz) ~= (cbz)
        error('lte:error','The length of the input data (%d) is not a multiple integer of the number of code blocks (%d)',B,C);
    end
    
    % Get number of bits in each code block (excluding Filler bits)
    Kd = Bd/C;
    
    % Find the minimum value of Z in all sets of lifting sizes in Table
    % 5.3.2-1, denoted as Zc, such that Kb*Zc>=Kd
    if nbg == 1
        Kb = 22;
    else
        if B > 640
            Kb = 10;
        elseif B > 560
            Kb = 9;
        elseif B > 192
            Kb = 8;
        else
            Kb = 6;
        end
    end
    Zlist = [2:16 18:2:32 36:4:64 72:8:112 120 128 144 160:16:256 288 320 352 384]; % All possible lifting sizes
    for Zc = Zlist
        if Kb*Zc >= Kd
            break;
        end
    end
    
    % Get number of bits (including Filler bits) to be encoded by LDPC
    % encoder
    if nbg == 1
        K = 22*Zc;
        N = 66*Zc;
    else
        K = 10*Zc;
        N = 50*Zc;
    end
    
    
    info.C = C;         % Number of code block segements
    info.Kd = Kd;       % Number of bits in each code block (may include CB-CRC bits but excluding Filler bits)
    info.K = K;         % Number of bits in each code block (including Filler bits)
    info.N = N;         % Circular buffer length (with 2*Zc bits punctured)
    info.ZC = Zc;       % Selected lifting size
    
end