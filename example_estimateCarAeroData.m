% [cl,cd,aeroBalance] = api.genCarAeroData('2415',-15,'2415',-15)
[cl1,cd1,aeroBalance1] = api.genCarAeroData('0015',-10,'0015',-10);
[cl2,cd2,aeroBalance2] = api.genCarAeroData('0015',-6.3,'0015',-8.1);
% [cl,cd,aeroBalance] = api.genCarAeroData('0015',0,'0015',0)

[cl1,cd1,aeroBalance1;cl2,cd2,aeroBalance2]