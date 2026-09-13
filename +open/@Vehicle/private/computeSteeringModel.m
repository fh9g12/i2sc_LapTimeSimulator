function steering = computeSteeringModel(raw)
    steering.a = (1-raw.df)*raw.L ; % distance of front axle from centre of mass [m]
    steering.b = -raw.df*raw.L ; % distance of rear axle from centre of mass [m]
    steering.C = 2*[raw.CF, raw.CF+raw.CR; raw.CF*steering.a, raw.CF*steering.a+raw.CR*steering.b] ; % steering model matrix
end
