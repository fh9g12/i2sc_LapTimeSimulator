function [Nf, Nr] = axleNormalLoads(Wz, Aero_Df, df, da)
    % axleNormalLoads - splits total normal load (mass weight Wz plus
    % aero downforce Aero_Df, using the signed convention Aero_Df<0 for
    % downforce that the rest of OpenLAP uses) into front/rear axle
    % totals, using the mechanical (df) and aero (da) front-load
    % fractions independently.
    Nf = df*Wz - da*Aero_Df ;
    Nr = (1-df)*Wz - (1-da)*Aero_Df ;
end
