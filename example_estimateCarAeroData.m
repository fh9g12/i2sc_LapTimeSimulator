% Example: turn two wing choices into whole-car Cl/Cd/aero-balance.
% AoA is NEGATIVE for downforce (matches api.naca4Aero; see api.genCarAeroData).
api.plotNACA('4515',-10) ; % front and rear wing, configuration 1 (same section/AoA both ends)
[cl1,cd1,aeroBalance1] = api.genCarAeroData('4515',-10,'4515',-10);

api.plotNACA('4815',-6.3) ; % front wing, configuration 2
api.plotNACA('4815',-8.1) ; % rear wing, configuration 2
[cl2,cd2,aeroBalance2] = api.genCarAeroData('4815',-6.3,'4815',-8.1);

[cl1,cd1,aeroBalance1;cl2,cd2,aeroBalance2]
