% generate Cl and Cd for a given Aerofoil at a given AoA
% the first input is the 4 digit code for a NACA 4-series Aerofoil
% the second input  is the requested Angle of attack
[cl,cd] = api.naca4Aero('2010',-2,InvertWing=true);

% Display the lift coefficient and drag coefficient
fprintf('---- Data for NACA 0012 @ 2 deg AoA ----\n')
fprintf('Lift Coefficient (Cl): %.4f\n', cl);
fprintf('Drag Coefficient (Cd): %.4f\n', cd);
fprintf('----------------------------------------\n')
fprintf('\n')

% plot a specific 4-series airfoil
api.plotNACA('0012')


%% Sweep AoAs

% Define the range of angles of attack
aoas = 0:-1:-20; % from 0 to 10 degrees
Cls = zeros(size(aoas));
Cds = zeros(size(aoas));

[Cls, Cds] = api.naca4Aero('0012', aoas, InvertWing=true);
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
    [Cls(i), Cds(i)] = api.naca4Aero([num2str(round(cambers(i))),'412'], -4, InvertWing=true);
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

