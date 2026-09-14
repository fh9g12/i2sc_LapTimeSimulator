% generate Cl and Cd for a given Aerofoil at a given AoA
% the first input is the 4 digit code for a NACA 4-series Aerofoil
% the second input is the requested Angle of attack (negative = downforce,
% since InvertWing defaults to true -- see api.naca4Aero)
section = '2412';
AoA = -5;
api.plotNACA(section,AoA) ; % see what this section/AoA actually looks like
[cl,cd] = api.naca4Aero(section,AoA);

% Display the lift coefficient and drag coefficient
fprintf('---- Data for NACA 2010 @ 2 deg AoA ----\n')
fprintf('Lift Coefficient (Cl): %.4f\n', cl);
fprintf('Drag Coefficient (Cd): %.4f\n', cd);
fprintf('----------------------------------------\n')
fprintf('\n')

% plot a specific 4-series airfoil
api.plotNACA('2412',-5)


%% Sweep AoAs

% Define the range of angles of attack
aoas = 0:-1:-20; % from 0 to -20 degrees
Cls = zeros(size(aoas));
Cds = zeros(size(aoas));

[Cls, Cds] = api.naca4Aero('0012', aoas);
% [Cls, Cds] = api.naca4Aero('2412', aoas);

figure;
tiledlayout(1,2)
nexttile()
hold on;
plot(aoas, Cls,'-d');
ylabel('Lift Coefficient (Cl)')
xlabel('AoA (deg)');
yyaxis right;
plot(aoas, Cds,'-o');
ylabel('Drag Coefficients (Cd)');
title('Lift and Drag Coefficients vs. Camber Number');

grid on;
nexttile()
plot(Cls,Cds,'-o')
title('Drag polar at different maximum cambers');
hold off;
grid on
xlabel('Lift Coefficient (Cl)')
ylabel('Drag Coefficient (Cd)')

%% sweep camber numbers

cambers = 1:8;
Cls = zeros(size(cambers));
Cds = zeros(size(cambers));
for i = 1:length(cambers)
    [Cls(i), Cds(i)] = api.naca4Aero([num2str(round(cambers(i))),'412'], -4);
end

figure;
tiledlayout(1,2)
nexttile()
hold on;
plot(cambers, Cls,'r-d');
ylabel('Lift Coefficient (Cl)')
xlabel('Camber Number');
yyaxis right;
plot(cambers, Cds,'b-o');
ylabel('Drag Coefficients (Cd)');
title('Lift and Drag Coefficients vs. Camber Number');

grid on;
nexttile()
plot(Cls,Cds,'-o')
title('Drag polar at different maximum cambers');
hold off;
grid on
xlabel('Lift Coefficient (Cl)')
ylabel('Drag Coefficient (Cd)')

