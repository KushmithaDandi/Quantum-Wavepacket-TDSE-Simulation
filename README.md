 # Quantum Wavepacket TDSE Simulation

MATLAB-based simulation of time-dependent quantum wavepacket motion in one-dimensional nanoelectronic devices using a finite-difference solution of the Time-Dependent Schrödinger Equation (TDSE) and an interactive graphical user interface.

## Overview

This repository contains the MATLAB implementation developed as part of an MSc project investigating the time-dependent behaviour of quantum wavepackets in one-dimensional nanoelectronic potential structures.

The simulation numerically solves the one-dimensional Time-Dependent Schrödinger Equation and enables the evolution of a Gaussian quantum wavepacket to be investigated under different potential-energy configurations.

## Features

- One-dimensional Time-Dependent Schrödinger Equation (TDSE)
- Finite-difference time-development method
- Gaussian wavepacket initialization and propagation
- Free-particle simulation
- Potential-step simulation
- Single rectangular potential barrier/well
- Double-barrier potential structure
- Linear potential
- Parabolic potential well
- Probability-density visualization
- Reflection and transmission analysis for scattering structures
- Calculation of quantum-mechanical observables
- Space-time visualization of wavepacket evolution
- Interactive MATLAB graphical user interface (GUI)

## Potential Structures

The simulation supports six potential-energy configurations:

1. Free particle
2. Potential step
3. Linear electric-field potential
4. Single rectangular potential hill/well
5. Parabolic potential well
6. Double rectangular barrier

These structures allow different quantum phenomena, including propagation, confinement, reflection, transmission, tunnelling and interference, to be investigated.

## Numerical Method

The one-dimensional Time-Dependent Schrödinger Equation is solved using a finite-difference time-development approach.

The complex wavefunction is represented using its real and imaginary components, which are updated sequentially over the spatial and temporal computational grids.

The probability density is calculated from:

|Psi(x,t)|^2 = Psi_R(x,t)^2 + Psi_I(x,t)^2

Numerical integration is used to evaluate probability and other quantum-mechanical observables.

## MATLAB GUI

An interactive MATLAB GUI was developed to provide:

- Simulation parameter control
- Potential selection
- Live wavepacket visualization
- Wavefunction analysis
- Transport analysis
- Space-time visualization
- Quantum-mechanical observables
- Numerical simulation results
- Export of simulation figures and results

## Software

Developed and tested using:

- MATLAB R2025b

## Running the Project

1. Download or clone this repository.
2. Open the project folder in MATLAB.
3. Ensure the required `.m` files are available on the MATLAB path.
4. Run the main GUI file:

   `QuantumWavepacketGUI_Source`

5. Select the required potential structure and simulation parameters.
6. Run the simulation and examine the generated wavefunction, probability-density, transport and observable results.

## Academic Project

**Project Title:** The Simulation of Time-Dependent Quantum Wavepacket Motion in Nanoelectronic Devices

**Programme:** MSc Embedded Systems and IC Design

**Institution:** Liverpool John Moores University

## Author

**Kushmitha Dandi**

MSc Embedded Systems and IC Design  
Liverpool John Moores University  
Liverpool, United Kingdom

## Academic Attribution

The project builds upon an existing MATLAB finite-difference TDSE program attributed in the source code to Ian Cooper, School of Physics, University of Sydney (2015).

The baseline numerical approach was extended for this MSc project to support additional potential structures, interactive parameter control, graphical user-interface functionality, transport analysis, visualization and result export.

Original source-code attribution and comments should be retained where applicable.

## Limitations

The current implementation models one-dimensional quantum transport using a finite spatial and temporal discretization. Fixed computational boundaries may produce artificial reflections when the wavepacket reaches the edges of the simulation domain.

Absorbing or transparent boundary conditions are not implemented in the current version and represent an area for future development.

## Future Work

Potential extensions include:

- Absorbing or transparent boundary conditions
- Grid and time-step convergence analysis
- Automated energy and wavelength sweeps
- Resonant-transmission analysis
- Position-dependent effective mass
- Realistic semiconductor heterostructure parameters
- Two-dimensional quantum transport modelling

## Disclaimer

This repository was developed for academic research and educational purposes as part of an MSc project.
