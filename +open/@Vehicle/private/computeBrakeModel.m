function brake = computeBrakeModel(raw)
    brake.br_pist_a = raw.br_nop*pi*(raw.br_pist_d/1000)^2/4 ; % [m2]
    brake.br_mast_a = pi*(raw.br_mast_d/1000)^2/4 ; % [m2]
    brake.beta = raw.tyre_radius/(raw.br_disc_d/2-raw.br_pad_h/2)/brake.br_pist_a/raw.br_pad_mu/4 ; % [Pa/N] per wheel
    brake.phi = brake.br_mast_a/raw.br_ped_r*2 ; % [-] for both systems
end
