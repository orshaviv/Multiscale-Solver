classdef CurrentState < handle
    properties
        %G stands for global and constant variables
        
        %Uniaxial
        lrG = sym('lr','positive');
        ltG = 1.69;
        
        %Biaxial
        riG = sym('ri','positive'); %Inner radius
        Pin = 90*133.322387415*1e-6; %Inner pressure (mmHg to MPa)
        lambda = 1.5;
        
        r
        R
        
        x
        w
        xNum
        wNum
        
        ri
        ro
        riNum = 0;
        roNum
        
        FT
        
        %Both Simulations
        p = sym('p','real');
        
        ufs = 0;
        nAMp
        nAM
        
        %Stretch Ratios
        lr
        lt
        lz
        
        lrNum = 0;
        ltNum
        lzNum
        
        dMArMA0
        dMAzMA0
        LMr
        LMz
        Lfor
        Lfoz
        eS2xr
        eS2yr
        eS2xz
        eS2yz
        
        x2cr
        x2cz
        y2cr
        y2cz
                
        I4SMCe
        I4SMCeNum
        
        sECM
        sSMC
        sMMy
        
        PMM
        PCU
        Pisom
    end
    
    methods
        
    end
end

