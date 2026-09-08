function QuantumWavepacketGUI_SourceAligned_V3
% ========================================================================
% QUANTUM WAVEPACKET DYNAMICS IN NANOELECTRONIC DEVICES
% Source-aligned GUI V3 for the 1D Time-Dependent Schrodinger Equation (TDSE)
% using the finite-difference time-development method.
%
% Core model retained from the supplied baseline solver:
%   * Gaussian wavepacket
%   * C1/C2/C3 finite-difference coefficients
%   * Sequential real/imaginary TDSE updates
%   * Simpson's 1/3 rule for full-domain integrations
%
% GUI / analysis extensions:
%   * Animated probability density + potential
%   * Real / imaginary wavefunction animation
%   * Source-aligned cases 1-6: free / step / electric / hill-well / parabolic / double barrier
%   * Reflection, transmission and interaction-region probabilities
%   * Double-barrier central-well probability
%   * Probability-conservation history
%   * Mean-position history
%   * Kinetic, potential and total energy histories
%   * 2D space-time probability-density heatmap
%   * 3D x-t-|psi|^2 probability surface
%   * Run / Pause / Stop / Reset / Export
%   * PDF, PNG, CSV and MAT export
%
% IMPORTANT PHYSICAL INTERPRETATION:
% R/T are shown only for Potential Step, Single Barrier and Double Barrier.
% For Free Particle, Linear Electric Field and Parabolic Well they are N/A.
% ========================================================================

clc;

%% =======================================================================
% COLOUR PALETTE
% ========================================================================
C.bg           = [0.94 0.96 0.985];
C.header       = [0.025 0.09 0.19];
C.panel        = [1.00 1.00 1.00];
C.section      = [0.03 0.28 0.58];
C.real         = [0.00 0.35 0.85];
C.imag         = [0.80 0.10 0.18];
C.prob         = [0.03 0.58 0.28];
C.potential    = [0.10 0.10 0.10];
C.reflection   = [0.82 0.12 0.12];
C.transmission = [0.05 0.55 0.24];
C.interaction  = [0.92 0.55 0.05];
C.well         = [0.42 0.20 0.75];
C.run          = [0.02 0.55 0.25];
C.pause        = [0.95 0.68 0.05];
C.stop         = [0.46 0.16 0.68];
C.reset        = [0.78 0.16 0.16];
C.export       = [0.18 0.36 0.72];

%% =======================================================================
% STORED VALUES FOR EXPORT
% ========================================================================
lastResults = struct();
lastX = [];
lastYReal = [];
lastYImag = [];
lastDensity = [];
lastPotential = [];
lastTimeHistory = [];
lastDensityHistory = [];
lastProbHistory = [];
lastXMeanHistory = [];
lastKHistory = [];
lastUHistory = [];
lastEHistory = [];
lastStepHistory = [];
lastRHistory = [];
lastTHistory = [];
lastIHistory = [];
lastWellHistory = [];
simulationHasRun = false;
stopRequested = false;

%% =======================================================================
% MAIN WINDOW
% ========================================================================
fig = uifigure( ...
    'Name','Quantum Wavepacket Dynamics', ...
    'Position',[20 20 1660 940], ...
    'Color',C.bg);

root = uigridlayout(fig,[2 1]);
root.RowHeight = {84,'1x'};
root.Padding = [8 8 8 8];
root.RowSpacing = 8;

%% =======================================================================
% HEADER
% ========================================================================
headerPanel = uipanel(root, ...
    'BackgroundColor',C.header, ...
    'BorderType','none');

headerGrid = uigridlayout(headerPanel,[2 1]);
headerGrid.RowHeight = {48,24};
headerGrid.Padding = [10 4 10 4];

uilabel(headerGrid, ...
    'Text','The Simulation of Time-Dependent Quantum Wavepacket Motion in Nanoelectronic Devices', ...
    'FontSize',22, ...
    'FontWeight','bold', ...
    'FontColor',[1 1 1], ...
    'HorizontalAlignment','center');

uilabel(headerGrid, ...
    'Text','1D TDSE  |  Finite-Difference Time Development  |  Interactive Quantum-Transport Analysis', ...
    'FontSize',12, ...
    'FontColor',[0.82 0.90 1.00], ...
    'HorizontalAlignment','center');

%% =======================================================================
% BODY
% ========================================================================
body = uigridlayout(root,[1 2]);
body.ColumnWidth = {355,'1x'};
body.ColumnSpacing = 8;
body.Padding = [0 0 0 0];

%% =======================================================================
% LEFT COLUMN - PARAMETERS / CONTROLS
% ========================================================================
inputPanel = uipanel(body, ...
    'Title','Simulation Control', ...
    'FontSize',13, ...
    'FontWeight','bold', ...
    'BackgroundColor',C.panel, ...
    'Scrollable','on');

inputContent = uipanel(inputPanel, ...
    'BorderType','none', ...
    'BackgroundColor',C.panel, ...
    'Position',[5 5 325 1100]);

inputGrid = uigridlayout(inputContent,[28 2]);
inputGrid.ColumnWidth = {165,'1x'};
inputGrid.RowHeight = { ...
    28,31,31,31, ...
    28,31,31,31, ...
    28,31,31,31,31,31,31, ...
    28,38,38,38,38,38, ...
    28,32,32,32,32,32,32};
inputGrid.RowSpacing = 6;
inputGrid.Padding = [8 8 8 8];

% Numerical parameters
sectionLabel(inputGrid,'NUMERICAL PARAMETERS');

uilabel(inputGrid,'Text','Spatial points Nx');
NxField = uieditfield(inputGrid,'numeric', ...
    'Value',1001, ...
    'Limits',[101 10001], ...
    'RoundFractionalValues','on');

uilabel(inputGrid,'Text','Time steps Nt');
NtField = uieditfield(inputGrid,'numeric', ...
    'Value',10000, ...
    'Limits',[100 100000], ...
    'RoundFractionalValues','on');

uilabel(inputGrid,'Text','Domain length L [nm]');
LField = uieditfield(inputGrid,'numeric','Value',4);

% Wavepacket parameters
sectionLabel(inputGrid,'WAVEPACKET PARAMETERS');

uilabel(inputGrid,'Text','Wavelength lambda [nm]');
lambdaField = uieditfield(inputGrid,'numeric','Value',0.16);

uilabel(inputGrid,'Text','Packet width s [nm]');
widthField = uieditfield(inputGrid,'numeric','Value',0.16);

uilabel(inputGrid,'Text','Initial position x0/L');
x0Field = uieditfield(inputGrid,'numeric', ...
    'Value',0.25, ...
    'Limits',[0.01 0.99]);

% Potential parameters
sectionLabel(inputGrid,'POTENTIAL STRUCTURE');

uilabel(inputGrid,'Text','Potential type');
potentialDrop = uidropdown(inputGrid, ...
    'Items',{ ...
    'Free Particle', ...
    'Potential Step', ...
    'Linear Electric Field', ...
    'Single Rectangular Hill / Well', ...
    'Parabolic Well', ...
    'Double Barrier'}, ...
    'Value','Parabolic Well', ...
    'ValueChangedFcn',@potentialChanged);

uilabel(inputGrid,'Text','Potential U0 [eV]');
U0Field = uieditfield(inputGrid,'numeric','Value',-600);

uilabel(inputGrid,'Text','Structure centre x/L');
centreField = uieditfield(inputGrid,'numeric', ...
    'Value',0.50, ...
    'Limits',[0.05 0.95]);

uilabel(inputGrid,'Text','Barrier width [nm]');
barrierWidthField = uieditfield(inputGrid,'numeric','Value',0.48);

uilabel(inputGrid,'Text','Well width [nm]');
wellWidthField = uieditfield(inputGrid,'numeric','Value',0.28);

uilabel(inputGrid,'Text','Display every N steps');
frameField = uieditfield(inputGrid,'numeric', ...
    'Value',100, ...
    'Limits',[1 10000], ...
    'RoundFractionalValues','on');

% Simulation controls
sectionLabel(inputGrid,'SIMULATION CONTROLS');

runButton = uibutton(inputGrid,'push', ...
    'Text','RUN SIMULATION', ...
    'FontWeight','bold', ...
    'FontColor',[1 1 1], ...
    'BackgroundColor',C.run, ...
    'ButtonPushedFcn',@runSimulation);
runButton.Layout.Column = [1 2];

pauseButton = uibutton(inputGrid,'state', ...
    'Text','PAUSE', ...
    'FontWeight','bold', ...
    'BackgroundColor',C.pause);

stopButton = uibutton(inputGrid,'push', ...
    'Text','STOP', ...
    'FontWeight','bold', ...
    'FontColor',[1 1 1], ...
    'BackgroundColor',C.stop, ...
    'ButtonPushedFcn',@stopSimulation);

resetButton = uibutton(inputGrid,'push', ...
    'Text','RESET', ...
    'FontWeight','bold', ...
    'FontColor',[1 1 1], ...
    'BackgroundColor',C.reset, ...
    'ButtonPushedFcn',@resetSimulation);

exportButton = uibutton(inputGrid,'push', ...
    'Text','EXPORT RESULTS', ...
    'FontWeight','bold', ...
    'FontColor',[1 1 1], ...
    'BackgroundColor',C.export, ...
    'Enable','off', ...
    'ButtonPushedFcn',@exportResults);
exportButton.Layout.Column = [1 2];

% Live numerical summary - compact 3 x 2 dashboard
sectionLabel(inputGrid,'LIVE NUMERICAL SUMMARY');

summaryDashboard = uipanel(inputGrid, ...
    'BackgroundColor',[0.985 0.99 1.00], ...
    'BorderType','none');
summaryDashboard.Layout.Row = [23 28];
summaryDashboard.Layout.Column = [1 2];

summaryCards = uigridlayout(summaryDashboard,[3 2]);
summaryCards.RowHeight = {'1x','1x','1x'};
summaryCards.ColumnWidth = {'1x','1x'};
summaryCards.RowSpacing = 7;
summaryCards.ColumnSpacing = 7;
summaryCards.Padding = [2 2 2 2];

statusLabel   = createDashboardCard(summaryCards,'STATUS','READY');
progressLabel = createDashboardCard(summaryCards,'PROGRESS','0 %');
timeLabel     = createDashboardCard(summaryCards,'SIMULATION TIME','0.0000 fs');
probLabel     = createDashboardCard(summaryCards,'TOTAL PROBABILITY','-');
positionLabel = createDashboardCard(summaryCards,'MEAN POSITION','-');
energyLabel   = createDashboardCard(summaryCards,'TOTAL ENERGY','-');

%% =======================================================================
% RIGHT COLUMN - TABS
% ========================================================================
tabGroup = uitabgroup(body);

tabLive        = uitab(tabGroup,'Title','Live Simulation');
tabWave        = uitab(tabGroup,'Title','Wavefunction');
tabTransport   = uitab(tabGroup,'Title','Transport');
tabSpaceTime   = uitab(tabGroup,'Title','Space-Time');
tabObservables = uitab(tabGroup,'Title','Observables');
tabResults     = uitab(tabGroup,'Title','Results');

%% =======================================================================
% LIVE SIMULATION TAB
% ========================================================================
liveGrid = uigridlayout(tabLive,[2 2]);
liveGrid.RowHeight = {'3x','1x'};
liveGrid.ColumnWidth = {'1.5x','1x'};
liveGrid.Padding = [8 8 8 8];
liveGrid.RowSpacing = 8;
liveGrid.ColumnSpacing = 8;

axLive = uiaxes(liveGrid);
axLive.Layout.Row = 1;
axLive.Layout.Column = [1 2];
title(axLive,'Live Probability Density and Potential');
xlabel(axLive,'Position x [nm]');
ylabel(axLive,'|psi(x,t)|^2');
grid(axLive,'on');
box(axLive,'on');

summaryPanel = uipanel(liveGrid, ...
    'Title','Transport / State Summary', ...
    'FontWeight','bold', ...
    'BackgroundColor',C.panel);
summaryPanel.Layout.Row = 2;
summaryPanel.Layout.Column = 1;

summaryGrid = uigridlayout(summaryPanel,[2 4]);
summaryGrid.RowHeight = {25,'1x'};
summaryGrid.ColumnWidth = {'1x','1x','1x','1x'};
summaryGrid.Padding = [6 6 6 6];

uilabel(summaryGrid,'Text','Reflection R', ...
    'HorizontalAlignment','center','FontWeight','bold');
uilabel(summaryGrid,'Text','Transmission T', ...
    'HorizontalAlignment','center','FontWeight','bold');
uilabel(summaryGrid,'Text','Interaction', ...
    'HorizontalAlignment','center','FontWeight','bold');
uilabel(summaryGrid,'Text','Well Probability', ...
    'HorizontalAlignment','center','FontWeight','bold');

reflectionLabel = uilabel(summaryGrid,'Text','N/A', ...
    'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
transmissionLabel = uilabel(summaryGrid,'Text','N/A', ...
    'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
interactionLabel = uilabel(summaryGrid,'Text','N/A', ...
    'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');
wellLabel = uilabel(summaryGrid,'Text','N/A', ...
    'HorizontalAlignment','center','FontSize',16,'FontWeight','bold');

infoPanel = uipanel(liveGrid, ...
    'Title','Potential Interpretation', ...
    'FontWeight','bold', ...
    'BackgroundColor',C.panel);
infoPanel.Layout.Row = 2;
infoPanel.Layout.Column = 2;

infoGrid = uigridlayout(infoPanel,[1 1]);
infoGrid.Padding = [8 8 8 8];

potentialInfoLabel = uilabel(infoGrid, ...
    'Text',potentialDescription(potentialDrop.Value), ...
    'WordWrap','on', ...
    'VerticalAlignment','top', ...
    'FontSize',11);

%% =======================================================================
% WAVEFUNCTION TAB
% ========================================================================
waveGrid = uigridlayout(tabWave,[3 1]);
waveGrid.RowHeight = {'1x','1x','1x'};
waveGrid.Padding = [8 8 8 8];
waveGrid.RowSpacing = 6;

axReal = uiaxes(waveGrid);
title(axReal,'Real Wavefunction');
xlabel(axReal,'Position x [nm]');
ylabel(axReal,'psi_R');
grid(axReal,'on'); box(axReal,'on');

axImag = uiaxes(waveGrid);
title(axImag,'Imaginary Wavefunction');
xlabel(axImag,'Position x [nm]');
ylabel(axImag,'psi_I');
grid(axImag,'on'); box(axImag,'on');

axProb = uiaxes(waveGrid);
title(axProb,'Probability Density');
xlabel(axProb,'Position x [nm]');
ylabel(axProb,'|psi|^2');
grid(axProb,'on'); box(axProb,'on');

%% =======================================================================
% TRANSPORT TAB
% ========================================================================
transportGrid = uigridlayout(tabTransport,[2 2]);
transportGrid.RowHeight = {'1x','1x'};
transportGrid.ColumnWidth = {'1x','1x'};
transportGrid.Padding = [8 8 8 8];
transportGrid.RowSpacing = 8;
transportGrid.ColumnSpacing = 8;

axPotential = uiaxes(transportGrid);
title(axPotential,'Potential Energy Profile');
xlabel(axPotential,'Position x [nm]');
ylabel(axPotential,'U [eV]');
grid(axPotential,'on'); box(axPotential,'on');

axRT = uiaxes(transportGrid);
title(axRT,'Reflection / Transmission / Interaction');
xlabel(axRT,'Time [fs]');
ylabel(axRT,'Probability');
ylim(axRT,[0 1.05]);
grid(axRT,'on'); box(axRT,'on');

axWell = uiaxes(transportGrid);
title(axWell,'Double-Barrier Central-Well Probability');
xlabel(axWell,'Time [fs]');
ylabel(axWell,'P_{well}');
ylim(axWell,[0 1.05]);
grid(axWell,'on'); box(axWell,'on');

axBalance = uiaxes(transportGrid);
title(axBalance,'Probability Conservation');
xlabel(axBalance,'Time [fs]');
ylabel(axBalance,'P_{total}');
grid(axBalance,'on'); box(axBalance,'on');

%% =======================================================================
% SPACE-TIME TAB
% ========================================================================
spaceGrid = uigridlayout(tabSpaceTime,[1 2]);
spaceGrid.ColumnWidth = {'1x','1x'};
spaceGrid.Padding = [8 8 8 8];
spaceGrid.ColumnSpacing = 8;

axHeatmap = uiaxes(spaceGrid);
title(axHeatmap,'2D Space-Time Probability Density');
xlabel(axHeatmap,'Position x [nm]');
ylabel(axHeatmap,'Time [fs]');
box(axHeatmap,'on');

ax3D = uiaxes(spaceGrid);
title(ax3D,'3D Space-Time Probability Surface');
xlabel(ax3D,'Position x [nm]');
ylabel(ax3D,'Time [fs]');
zlabel(ax3D,'|psi(x,t)|^2');
grid(ax3D,'on'); box(ax3D,'on');
view(ax3D,45,30);

%% =======================================================================
% OBSERVABLES TAB
% ========================================================================
obsGrid = uigridlayout(tabObservables,[2 2]);
obsGrid.RowHeight = {'1x','1x'};
obsGrid.ColumnWidth = {'1x','1x'};
obsGrid.Padding = [8 8 8 8];
obsGrid.RowSpacing = 8;
obsGrid.ColumnSpacing = 8;

axEnergy = uiaxes(obsGrid);
title(axEnergy,'Energy Evolution');
xlabel(axEnergy,'Time [fs]');
ylabel(axEnergy,'Energy [eV]');
grid(axEnergy,'on'); box(axEnergy,'on');

axXMean = uiaxes(obsGrid);
title(axXMean,'Mean Position Evolution');
xlabel(axXMean,'Time [fs]');
ylabel(axXMean,'<x> [nm]');
grid(axXMean,'on'); box(axXMean,'on');

axProbability = uiaxes(obsGrid);
title(axProbability,'Total Probability');
xlabel(axProbability,'Time [fs]');
ylabel(axProbability,'P(t)');
grid(axProbability,'on'); box(axProbability,'on');

axUncertainty = uiaxes(obsGrid);
title(axUncertainty,'Final Uncertainty Check');
xlabel(axUncertainty,'Quantity');
ylabel(axUncertainty,'kg m^2/s');
grid(axUncertainty,'on'); box(axUncertainty,'on');

%% =======================================================================
% RESULTS TAB
% ========================================================================
resultsGrid = uigridlayout(tabResults,[1 1]);
resultsGrid.Padding = [8 8 8 8];

resultsTable = uitable(resultsGrid);
resultsTable.ColumnName = {'Physical Quantity','Calculated Value','Unit'};
resultsTable.ColumnWidth = {330,230,180};
resultsTable.RowName = {};

% Set initial control state
potentialChanged();

%% =======================================================================
% RUN SIMULATION
% ========================================================================
    function runSimulation(~,~)

        simulationHasRun = false;
        stopRequested = false;
        exportButton.Enable = 'off';
        runButton.Enable = 'off';
        pauseButton.Value = false;
        pauseButton.Text = 'PAUSE';

        statusLabel.Text = 'RUNNING';
        timeLabel.Text = '0.0000 fs';
        progressLabel.Text = '0 %';

        % Physical constants
        me   = 9.10938291e-31;
        hbar = 1.054571726e-34;
        e    = 1.602176565e-19;
        h    = 2*pi*hbar;

        % User parameters
        Nx = round(NxField.Value);
        Nt = round(NtField.Value);

        if mod(Nx,2)==0
            uialert(fig, ...
                'Nx must be odd because Simpson''s 1/3 rule is used.', ...
                'Invalid Spatial Grid');
            runButton.Enable = 'on';
            statusLabel.Text = 'Ready';
            return
        end

        if LField.Value<=0 || lambdaField.Value<=0 || widthField.Value<=0
            uialert(fig, ...
                'Domain length, wavelength and packet width must be positive.', ...
                'Invalid Parameter');
            runButton.Enable = 'on';
            statusLabel.Text = 'Ready';
            return
        end

        L = LField.Value*1e-9;
        wL = lambdaField.Value*1e-9;
        s = widthField.Value*1e-9;

        U0 = U0Field.Value;
        structureCentre = centreField.Value*L;
        barrierWidth = barrierWidthField.Value*1e-9;
        wellWidth = wellWidthField.Value*1e-9;
        frameStep = max(1,round(frameField.Value));

        % Spatial grid
        x = linspace(0,L,Nx);
        dx = x(2)-x(1);

        nx0 = round(x0Field.Value*Nx);
        nx0 = max(2,min(Nx-1,nx0));

        % Baseline FDTD coefficients
        C1 = 1/10;
        dt = C1*2*me*dx^2/hbar;
        C2 = e*dt/hbar;
        C3eV = -hbar^2/(2*me*dx^2*e);

        KE_theoretical = (h/wL)^2/(2*me*e);

        % Potential construction
        U = zeros(1,Nx);

        xLeft = NaN;
        xRight = NaN;

        b1Left = NaN;
        b1Right = NaN;
        wellLeft = NaN;
        wellRight = NaN;
        b2Left = NaN;
        b2Right = NaN;

        switch potentialDrop.Value

            case 'Free Particle'
                % Source case 1
                U(:)=0;

            case 'Potential Step'
                % Source case 2: step starts at NxC (domain centre).
                xLeft = x(round(Nx/2));
                xRight = xLeft;
                U(round(Nx/2):end)=U0;

            case 'Linear Electric Field'
                % Source case 3
                U = -(U0/L).*x + U0;

            case 'Single Rectangular Hill / Well'
                % Source case 4.
                % The original code uses a finite rectangular region and the
                % sign of U0 determines hill (>0) or well (<0).
                %
                % Original source indices:
                %   w1 = -80
                %   U(NxC-40 : NxC+40-w1) = U0
                % which corresponds to 161 grid samples for Nx=1001.
                NxC = round(Nx/2);
                w1 = -80;
                idx1 = NxC-2*40/2;
                idx2 = NxC+2*40/2-w1;

                idx1 = max(1,idx1);
                idx2 = min(Nx,idx2);

                U(idx1:idx2)=U0;

                xLeft = x(idx1);
                xRight = x(idx2);

            case 'Parabolic Well'
                % Source case 5
                a = 4*abs(U0)/L^2;
                b = -4*abs(U0)/L;
                c = 0;
                U = a.*x.^2+b.*x+c;

            case 'Double Barrier'
                % Source case 6 added to se_fdtd_01:
                % DB_height = 62 eV
                % DB_width  = 18 grid points
                % DB_well   = 70 grid points
                % structure centred at NxC.
                NxC = round(Nx/2);

                DB_height = 62;
                DB_width  = 18;
                DB_well   = 70;

                DB_start = NxC - round((2*DB_width + DB_well)/2);

                DB1_start = DB_start;
                DB1_end   = DB1_start + DB_width - 1;

                DB2_start = DB1_end + DB_well + 1;
                DB2_end   = DB2_start + DB_width - 1;

                if DB1_start < 1 || DB2_end > Nx
                    invalidGeometry('Double-barrier structure extends outside the computational domain.');
                    return
                end

                U(:)=0;
                U(DB1_start:DB1_end)=DB_height;
                U(DB2_start:DB2_end)=DB_height;

                b1Left = x(DB1_start);
                b1Right = x(DB1_end);
                wellLeft = x(DB1_end+1);
                wellRight = x(DB2_start-1);
                b2Left = x(DB2_start);
                b2Right = x(DB2_end);

                xLeft = b1Left;
                xRight = b2Right;
        end

        % Potential plot
        cla(axPotential);
        plot(axPotential,x*1e9,U, ...
            'Color',C.potential,'LineWidth',2);
        title(axPotential,['Potential: ' potentialDrop.Value]);
        xlabel(axPotential,'Position x [nm]');
        ylabel(axPotential,'U [eV]');
        grid(axPotential,'on');
        box(axPotential,'on');
        addPotentialMarkers(axPotential,potentialDrop.Value, ...
            xLeft,xRight,b1Left,b1Right,wellLeft,wellRight,b2Left,b2Right);

        % Initial Gaussian wavepacket
        yR = zeros(1,Nx);
        yI = zeros(1,Nx);

        for nx=1:Nx
            envelope = exp(-0.5*((x(nx)-x(nx0))/s)^2);
            phase = 2*pi*(x(nx)-x(nx0))/wL;
            yR(nx) = envelope*cos(phase);
            yI(nx) = envelope*sin(phase);
        end

        % Normalize
        density = yR.^2+yI.^2;
        A = simpsonGUI(density,0,L);
        yR = yR./sqrt(A);
        yI = yI./sqrt(A);
        density = yR.^2+yI.^2;

        % Initial kinetic energy
        Kinitial = calculateKineticEnergy(yR,yI,C3eV,L,Nx);

        % Prepare live plots
        cla(axLive);
        yyaxis(axLive,'left');
        hLiveProb = plot(axLive,x*1e9,density, ...
            'Color',C.prob,'LineWidth',2.3);
        ylabel(axLive,'|psi(x,t)|^2');

        yyaxis(axLive,'right');
        plot(axLive,x*1e9,U, ...
            'Color',C.potential,'LineWidth',1.4);
        ylabel(axLive,'U [eV]');
        xlabel(axLive,'Position x [nm]');
        title(axLive,'Live Probability Density and Potential');
        grid(axLive,'on'); box(axLive,'on');

        yyaxis(axLive,'left');
        xMean0 = simpsonGUI(x.*density,0,L);
        meanLine = xline(axLive,real(xMean0)*1e9,'--','<x>', ...
            'LineWidth',1.4);
        addPotentialMarkers(axLive,potentialDrop.Value, ...
            xLeft,xRight,b1Left,b1Right,wellLeft,wellRight,b2Left,b2Right);

        cla(axReal);
        yyaxis(axReal,'left');
        hReal = plot(axReal,x*1e9,yR,'Color',C.real,'LineWidth',1.7);
        ylabel(axReal,'psi_R');
        yyaxis(axReal,'right');
        plot(axReal,x*1e9,U,'Color',C.potential,'LineWidth',1);
        ylabel(axReal,'U [eV]');
        xlabel(axReal,'Position x [nm]');
        grid(axReal,'on'); box(axReal,'on');

        cla(axImag);
        yyaxis(axImag,'left');
        hImag = plot(axImag,x*1e9,yI,'Color',C.imag,'LineWidth',1.7);
        ylabel(axImag,'psi_I');
        yyaxis(axImag,'right');
        plot(axImag,x*1e9,U,'Color',C.potential,'LineWidth',1);
        ylabel(axImag,'U [eV]');
        xlabel(axImag,'Position x [nm]');
        grid(axImag,'on'); box(axImag,'on');

        cla(axProb);
        yyaxis(axProb,'left');
        hProb = plot(axProb,x*1e9,density,'Color',C.prob,'LineWidth',2);
        ylabel(axProb,'|psi|^2');
        yyaxis(axProb,'right');
        plot(axProb,x*1e9,U,'Color',C.potential,'LineWidth',1);
        ylabel(axProb,'U [eV]');
        xlabel(axProb,'Position x [nm]');
        grid(axProb,'on'); box(axProb,'on');

        % Transport/history plot handles
        cla(axRT);
        hold(axRT,'on');
        hR = plot(axRT,nan,nan,'Color',C.reflection,'LineWidth',2, ...
            'DisplayName','Reflection');
        hT = plot(axRT,nan,nan,'Color',C.transmission,'LineWidth',2, ...
            'DisplayName','Transmission');
        hI = plot(axRT,nan,nan,'Color',C.interaction,'LineWidth',2, ...
            'DisplayName','Interaction');
        legend(axRT,'Location','best');
        hold(axRT,'off');
        ylim(axRT,[0 1.05]);
        xlabel(axRT,'Time [fs]');
        ylabel(axRT,'Probability');
        title(axRT,'Reflection / Transmission / Interaction');
        grid(axRT,'on');

        cla(axWell);
        hWell = plot(axWell,nan,nan,'Color',C.well,'LineWidth',2);
        xlabel(axWell,'Time [fs]');
        ylabel(axWell,'P_{well}');
        title(axWell,'Double-Barrier Central-Well Probability');
        ylim(axWell,[0 1.05]);
        grid(axWell,'on');

        cla(axBalance);
        hBalance = plot(axBalance,nan,nan,'LineWidth',2);
        hold(axBalance,'on');
        yline(axBalance,1,'--');
        hold(axBalance,'off');
        xlabel(axBalance,'Time [fs]');
        ylabel(axBalance,'P_{total}');
        title(axBalance,'Probability Conservation');
        grid(axBalance,'on');

        % Preallocate histories
        numFrames = ceil(Nt/frameStep)+2;
        densityHistory = zeros(numFrames,Nx);
        timeHistory = zeros(numFrames,1);
        probHistory = zeros(numFrames,1);
        xMeanHistory = zeros(numFrames,1);
        KHistory = zeros(numFrames,1);
        UHistory = zeros(numFrames,1);
        EHistory = zeros(numFrames,1);
        stepHistory = zeros(numFrames,1);
        RHistory = nan(numFrames,1);
        THistory = nan(numFrames,1);
        IHistory = nan(numFrames,1);
        wellHistory = nan(numFrames,1);

        frameCounter = 1;

        % Store t = 0 state
        P0 = simpsonGUI(density,0,L);
        x0avg = simpsonGUI(x.*density,0,L);
        U0avg = simpsonGUI(U.*density,0,L);
        K0avg = calculateKineticEnergy(yR,yI,C3eV,L,Nx);

        densityHistory(frameCounter,:) = density;
        timeHistory(frameCounter) = 0;
        probHistory(frameCounter) = real(P0);
        xMeanHistory(frameCounter) = real(x0avg);
        KHistory(frameCounter) = real(K0avg);
        UHistory(frameCounter) = real(U0avg);
        EHistory(frameCounter) = real(K0avg+U0avg);
        stepHistory(frameCounter) = 0;

        [R0,T0,I0,W0,app0] = transportProbabilities( ...
            density,x,potentialDrop.Value, ...
            xLeft,xRight,wellLeft,wellRight);

        if app0
            RHistory(frameCounter)=real(R0);
            THistory(frameCounter)=real(T0);
            IHistory(frameCounter)=real(I0);
            if ~isnan(W0)
                wellHistory(frameCounter)=real(W0);
            end
        end

        % Time propagation
        ntCompleted = 0;

        for nt=1:Nt

            ntCompleted = nt;

            if stopRequested
                statusLabel.Text = 'STOPPED';
                break
            end

            while pauseButton.Value
                pauseButton.Text = 'RESUME';
                statusLabel.Text = 'PAUSED';
                pause(0.05);
                drawnow;

                if stopRequested || ~isvalid(fig)
                    break
                end
            end

            if stopRequested || ~isvalid(fig)
                break
            end

            pauseButton.Text = 'PAUSE';
            statusLabel.Text = 'RUNNING';

            % Update real component
            for nx=2:Nx-1
                yR(nx)=yR(nx) ...
                    -C1*(yI(nx+1)-2*yI(nx)+yI(nx-1)) ...
                    +C2*U(nx)*yI(nx);
            end

            % Update imaginary component
            for nx=2:Nx-1
                yI(nx)=yI(nx) ...
                    +C1*(yR(nx+1)-2*yR(nx)+yR(nx-1)) ...
                    -C2*U(nx)*yR(nx);
            end

            % Fixed boundary conditions
            yR(1)=0; yR(end)=0;
            yI(1)=0; yI(end)=0;

            % Live/display update
            if mod(nt,frameStep)==0 || nt==Nt

                density = yR.^2+yI.^2;
                frameCounter = frameCounter+1;

                timeNow = nt*dt;
                timeFs = timeNow*1e15;

                Pnow = simpsonGUI(density,0,L);
                xNow = simpsonGUI(x.*density,0,L);
                Unow = simpsonGUI(U.*density,0,L);
                Know = calculateKineticEnergy(yR,yI,C3eV,L,Nx);
                Enow = Know+Unow;

                densityHistory(frameCounter,:) = density;
                timeHistory(frameCounter) = timeNow;
                probHistory(frameCounter) = real(Pnow);
                xMeanHistory(frameCounter) = real(xNow);
                KHistory(frameCounter) = real(Know);
                UHistory(frameCounter) = real(Unow);
                EHistory(frameCounter) = real(Enow);
                stepHistory(frameCounter) = nt;

                [R,T,Pinteraction,Pwell,applicable] = transportProbabilities( ...
                    density,x,potentialDrop.Value, ...
                    xLeft,xRight,wellLeft,wellRight);

                if applicable
                    RHistory(frameCounter)=real(R);
                    THistory(frameCounter)=real(T);
                    IHistory(frameCounter)=real(Pinteraction);

                    reflectionLabel.Text = sprintf('%.4f',real(R));
                    transmissionLabel.Text = sprintf('%.4f',real(T));
                    interactionLabel.Text = sprintf('%.4f',real(Pinteraction));

                    if ~isnan(Pwell)
                        wellHistory(frameCounter)=real(Pwell);
                        wellLabel.Text = sprintf('%.4f',real(Pwell));
                    else
                        wellLabel.Text = 'N/A';
                    end
                else
                    reflectionLabel.Text = 'N/A';
                    transmissionLabel.Text = 'N/A';
                    interactionLabel.Text = 'N/A';
                    wellLabel.Text = 'N/A';
                end

                % Update wavefunction animation
                hLiveProb.YData = density;
                meanLine.Value = real(xNow)*1e9;

                hReal.YData = yR;
                hImag.YData = yI;
                hProb.YData = density;

                title(axLive,sprintf( ...
                    'Live Probability Density | Step %d / %d | t = %.4f fs', ...
                    nt,Nt,timeFs));
                title(axReal,sprintf('Real Wavefunction | Step %d',nt));
                title(axImag,sprintf('Imaginary Wavefunction | Step %d',nt));
                title(axProb,sprintf('Probability Density | Step %d',nt));

                % Update transport plots
                used = 1:frameCounter;
                tUsedFs = timeHistory(used)*1e15;

                if applicable
                    hR.XData = tUsedFs;
                    hR.YData = RHistory(used);
                    hT.XData = tUsedFs;
                    hT.YData = THistory(used);
                    hI.XData = tUsedFs;
                    hI.YData = IHistory(used);
                end

                if strcmp(potentialDrop.Value,'Double Barrier')
                    hWell.XData = tUsedFs;
                    hWell.YData = wellHistory(used);
                end

                hBalance.XData = tUsedFs;
                hBalance.YData = probHistory(used);

                % Update summary boxes
                timeLabel.Text = sprintf('%.4f fs',timeFs);
                progressLabel.Text = sprintf('%.1f %%',100*nt/Nt);
                probLabel.Text = sprintf('%.6f',real(Pnow));
                positionLabel.Text = sprintf('%.5f nm',real(xNow)*1e9);
                energyLabel.Text = sprintf('%.4f eV',real(Enow));

                drawnow limitrate;
            end
        end

        % Final state
        density = yR.^2+yI.^2;
        prob = simpsonGUI(density,0,L);
        xavg = simpsonGUI(x.*density,0,L);
        Uavg = simpsonGUI(U.*density,0,L);
        Kavg = calculateKineticEnergy(yR,yI,C3eV,L,Nx);
        Eavg = Uavg+Kavg;

        % Momentum and velocity
        [pavg,p2avg] = calculateMomentum(yR,yI,dx,hbar,L,Nx);
        vavg = pavg/me;

        % Position uncertainty
        x2avg = simpsonGUI(x.^2.*density,0,L);
        delta_x = sqrt(max(0,real(x2avg-xavg^2)));

        % Momentum uncertainty
        delta_p = sqrt(max(0,real(p2avg-pavg^2)));
        dxdp = delta_x*delta_p;

        % Final transport
        [Rfinal,Tfinal,Pfinal,PwellFinal,applicableFinal] = ...
            transportProbabilities(density,x,potentialDrop.Value, ...
            xLeft,xRight,wellLeft,wellRight);

        if applicableFinal
            Rtext = sprintf('%.6f',real(Rfinal));
            Ttext = sprintf('%.6f',real(Tfinal));
            Itext = sprintf('%.6f',real(Pfinal));
            reflectionLabel.Text = sprintf('%.4f',real(Rfinal));
            transmissionLabel.Text = sprintf('%.4f',real(Tfinal));
            interactionLabel.Text = sprintf('%.4f',real(Pfinal));

            if ~isnan(PwellFinal)
                Wtext = sprintf('%.6f',real(PwellFinal));
                wellLabel.Text = sprintf('%.4f',real(PwellFinal));
            else
                Wtext = 'N/A';
                wellLabel.Text = 'N/A';
            end
        else
            Rtext = 'N/A';
            Ttext = 'N/A';
            Itext = 'N/A';
            Wtext = 'N/A';
            Rfinal = NaN;
            Tfinal = NaN;
            Pfinal = NaN;
            PwellFinal = NaN;
            reflectionLabel.Text = 'N/A';
            transmissionLabel.Text = 'N/A';
            interactionLabel.Text = 'N/A';
            wellLabel.Text = 'N/A';
        end

        % Trim history arrays
        used = 1:frameCounter;
        densityHistory = densityHistory(used,:);
        timeHistory = timeHistory(used);
        probHistory = probHistory(used);
        xMeanHistory = xMeanHistory(used);
        KHistory = KHistory(used);
        UHistory = UHistory(used);
        EHistory = EHistory(used);
        stepHistory = stepHistory(used);
        RHistory = RHistory(used);
        THistory = THistory(used);
        IHistory = IHistory(used);
        wellHistory = wellHistory(used);

        % 2D heatmap
        cla(axHeatmap);
        imagesc(axHeatmap, ...
            x*1e9, ...
            timeHistory*1e15, ...
            densityHistory);
        axis(axHeatmap,'xy');
        xlabel(axHeatmap,'Position x [nm]');
        ylabel(axHeatmap,'Time [fs]');
        title(axHeatmap,'2D Space-Time Probability Density');
        colorbar(axHeatmap);
        box(axHeatmap,'on');

        % 3D probability surface
        cla(ax3D);
        [X3D,T3D] = meshgrid(x*1e9,timeHistory*1e15);
        surf(ax3D,X3D,T3D,densityHistory,'EdgeColor','none');
        xlabel(ax3D,'Position x [nm]');
        ylabel(ax3D,'Time [fs]');
        zlabel(ax3D,'|psi(x,t)|^2');
        title(ax3D,'3D Space-Time Probability Surface');
        view(ax3D,45,30);
        grid(ax3D,'on');
        box(ax3D,'on');
        colorbar(ax3D);

        % Energy histories
        cla(axEnergy);
        hold(axEnergy,'on');
        plot(axEnergy,timeHistory*1e15,KHistory,'LineWidth',1.5, ...
            'DisplayName','Kinetic');
        plot(axEnergy,timeHistory*1e15,UHistory,'LineWidth',1.5, ...
            'DisplayName','Potential');
        plot(axEnergy,timeHistory*1e15,EHistory,'LineWidth',2.2, ...
            'DisplayName','Total');
        hold(axEnergy,'off');
        legend(axEnergy,'Location','best');
        xlabel(axEnergy,'Time [fs]');
        ylabel(axEnergy,'Energy [eV]');
        title(axEnergy,'Energy Evolution');
        grid(axEnergy,'on');

        % Mean position
        cla(axXMean);
        plot(axXMean,timeHistory*1e15,xMeanHistory*1e9,'LineWidth',2);
        xlabel(axXMean,'Time [fs]');
        ylabel(axXMean,'<x> [nm]');
        title(axXMean,'Mean Position Evolution');
        grid(axXMean,'on');

        % Probability conservation
        cla(axProbability);
        plot(axProbability,timeHistory*1e15,probHistory,'LineWidth',2);
        hold(axProbability,'on');
        yline(axProbability,1,'--');
        hold(axProbability,'off');
        xlabel(axProbability,'Time [fs]');
        ylabel(axProbability,'P(t)');
        title(axProbability,'Total Probability Conservation');
        grid(axProbability,'on');

        % Uncertainty comparison
        cla(axUncertainty);
        bar(axUncertainty,[real(dxdp),hbar/2]);
        axUncertainty.XTick = [1 2];
        axUncertainty.XTickLabel = {'Delta x Delta p','hbar / 2'};
        ylabel(axUncertainty,'kg m^2/s');
        title(axUncertainty,'Heisenberg Uncertainty Check');
        grid(axUncertainty,'on');

        % Results table
        resultsTable.Data = {
            'Potential Type', potentialDrop.Value, ''
            'Total Probability', sprintf('%.6f',real(prob)), ''
            'Reflection Probability R', Rtext, ''
            'Transmission Probability T', Ttext, ''
            'Interaction Probability', Itext, ''
            'Central-Well Probability', Wtext, ''
            'Mean Position <x>', sprintf('%.6f',real(xavg)*1e9), 'nm'
            'Mean Momentum <p>', sprintf('%.4e',real(pavg)), 'kg m/s'
            'Mean Velocity <v>', sprintf('%.4e',real(vavg)), 'm/s'
            'Theoretical Kinetic Energy', sprintf('%.4f',real(KE_theoretical)), 'eV'
            'Initial Kinetic Energy', sprintf('%.4f',real(Kinitial)), 'eV'
            'Final Kinetic Energy <K>', sprintf('%.4f',real(Kavg)), 'eV'
            'Potential Energy <U>', sprintf('%.4f',real(Uavg)), 'eV'
            'Total Energy <E>', sprintf('%.4f',real(Eavg)), 'eV'
            'Position Uncertainty Delta x', sprintf('%.4e',real(delta_x)), 'm'
            'Momentum Uncertainty Delta p', sprintf('%.4e',real(delta_p)), 'kg m/s'
            'Uncertainty Product Delta x Delta p', sprintf('%.4e',real(dxdp)), 'kg m^2/s'
            'hbar / 2', sprintf('%.4e',hbar/2), 'kg m^2/s'
            'Time Step dt', sprintf('%.4e',dt), 's'
            'Final Simulation Time', sprintf('%.4e',ntCompleted*dt), 's'
            };

        % Store all outputs for export
        lastX = x;
        lastYReal = yR;
        lastYImag = yI;
        lastDensity = density;
        lastPotential = U;
        lastTimeHistory = timeHistory;
        lastDensityHistory = densityHistory;
        lastProbHistory = probHistory;
        lastXMeanHistory = xMeanHistory;
        lastKHistory = KHistory;
        lastUHistory = UHistory;
        lastEHistory = EHistory;
        lastStepHistory = stepHistory;
        lastRHistory = RHistory;
        lastTHistory = THistory;
        lastIHistory = IHistory;
        lastWellHistory = wellHistory;

        lastResults.PotentialType = potentialDrop.Value;
        lastResults.Nx = Nx;
        lastResults.NtRequested = Nt;
        lastResults.NtCompleted = ntCompleted;
        lastResults.DomainLength_nm = L*1e9;
        lastResults.Wavelength_nm = wL*1e9;
        lastResults.PacketWidth_nm = s*1e9;
        lastResults.InitialPositionFraction = x0Field.Value;
        if strcmp(potentialDrop.Value,'Double Barrier')
            lastResults.PotentialHeight_eV = 62;
            lastResults.BarrierWidth_nm = 18*dx*1e9;
            lastResults.WellWidth_nm = 70*dx*1e9;
        else
            lastResults.PotentialHeight_eV = U0;
            lastResults.BarrierWidth_nm = barrierWidth*1e9;
            lastResults.WellWidth_nm = wellWidth*1e9;
        end
        lastResults.TotalProbability = real(prob);
        lastResults.Reflection = real(Rfinal);
        lastResults.Transmission = real(Tfinal);
        lastResults.InteractionProbability = real(Pfinal);
        lastResults.CentralWellProbability = real(PwellFinal);
        lastResults.MeanPosition_nm = real(xavg)*1e9;
        lastResults.MeanMomentum = real(pavg);
        lastResults.MeanVelocity = real(vavg);
        lastResults.TheoreticalKE_eV = real(KE_theoretical);
        lastResults.InitialKE_eV = real(Kinitial);
        lastResults.FinalKE_eV = real(Kavg);
        lastResults.PotentialEnergy_eV = real(Uavg);
        lastResults.TotalEnergy_eV = real(Eavg);
        lastResults.PositionUncertainty_m = real(delta_x);
        lastResults.MomentumUncertainty = real(delta_p);
        lastResults.UncertaintyProduct = real(dxdp);
        lastResults.HbarOver2 = hbar/2;
        lastResults.TimeStep_s = dt;
        lastResults.FinalSimulationTime_s = ntCompleted*dt;

        simulationHasRun = true;

        if stopRequested
            statusLabel.Text = 'STOPPED';
        else
            statusLabel.Text = 'COMPLETED';
            timeLabel.Text = sprintf('%.4f fs',Nt*dt*1e15);
            progressLabel.Text = '100 %';
        end

        runButton.Enable = 'on';
        exportButton.Enable = 'on';
        pauseButton.Value = false;
        pauseButton.Text = 'PAUSE';
        stopRequested = false;
    end

%% =======================================================================
% STOP SIMULATION
% ========================================================================
    function stopSimulation(~,~)
        stopRequested = true;
        pauseButton.Value = false;
        pauseButton.Text = 'PAUSE';
        statusLabel.Text = 'STOPPING...';
        drawnow;
    end

%% =======================================================================
% RESET
% ========================================================================
    function resetSimulation(~,~)
        stopRequested = true;
        pauseButton.Value = false;
        pauseButton.Text = 'PAUSE';

        cla(axLive);
        cla(axReal);
        cla(axImag);
        cla(axProb);
        cla(axPotential);
        cla(axRT);
        cla(axWell);
        cla(axBalance);
        cla(axHeatmap);
        cla(ax3D);
        cla(axEnergy);
        cla(axXMean);
        cla(axProbability);
        cla(axUncertainty);

        resultsTable.Data = {};

        reflectionLabel.Text = 'N/A';
        transmissionLabel.Text = 'N/A';
        interactionLabel.Text = 'N/A';
        wellLabel.Text = 'N/A';

        statusLabel.Text = 'READY';
        timeLabel.Text = '0.0000 fs';
        progressLabel.Text = '0 %';
        probLabel.Text = '-';
        positionLabel.Text = '-';
        energyLabel.Text = '-';

        simulationHasRun = false;
        exportButton.Enable = 'off';
        runButton.Enable = 'on';
        stopRequested = false;
    end

%% =======================================================================
% EXPORT RESULTS
% ========================================================================
    function exportResults(~,~)

        if ~simulationHasRun
            uialert(fig,'Run a simulation before exporting results.', ...
                'No Simulation Results');
            return
        end

        exportFolder = uigetdir(pwd,'Select Folder for Simulation Results');
        if exportFolder==0
            return
        end

        stamp = datestr(now,'yyyy-mm-dd_HH-MM-SS');

        % Complete GUI
        try
            exportapp(fig,fullfile(exportFolder, ...
                ['QuantumWavepacket_GUI_' stamp '.pdf']));
        catch ME
            warning('GUI PDF export failed: %s',ME.message);
        end

        try
            exportapp(fig,fullfile(exportFolder, ...
                ['QuantumWavepacket_GUI_' stamp '.png']));
        catch ME
            warning('GUI PNG export failed: %s',ME.message);
        end

        % Individual plots
        exportgraphics(axLive,fullfile(exportFolder, ...
            ['Live_Wavepacket_' stamp '.png']),'Resolution',300);
        exportgraphics(axPotential,fullfile(exportFolder, ...
            ['Potential_Profile_' stamp '.png']),'Resolution',300);
        exportgraphics(axHeatmap,fullfile(exportFolder, ...
            ['SpaceTime_Heatmap_' stamp '.png']),'Resolution',300);
        exportgraphics(ax3D,fullfile(exportFolder, ...
            ['SpaceTime_3D_' stamp '.png']),'Resolution',300);
        exportgraphics(axEnergy,fullfile(exportFolder, ...
            ['Energy_Evolution_' stamp '.png']),'Resolution',300);
        exportgraphics(axProbability,fullfile(exportFolder, ...
            ['Probability_Conservation_' stamp '.png']),'Resolution',300);

        if any(~isnan(lastRHistory))
            exportgraphics(axRT,fullfile(exportFolder, ...
                ['Transport_History_' stamp '.png']),'Resolution',300);
        end

        if any(~isnan(lastWellHistory))
            exportgraphics(axWell,fullfile(exportFolder, ...
                ['Well_Probability_' stamp '.png']),'Resolution',300);
        end

        % Summary CSV
        quantity = {
            'Potential Type'
            'Spatial Grid Points Nx'
            'Requested Time Steps Nt'
            'Completed Time Steps'
            'Domain Length'
            'Wavelength'
            'Wavepacket Width'
            'Initial Position x0/L'
            'Potential Height'
            'Barrier Width'
            'Well Width'
            'Time Step'
            'Final Simulation Time'
            'Total Probability'
            'Reflection Probability'
            'Transmission Probability'
            'Interaction Probability'
            'Central-Well Probability'
            'Mean Position'
            'Mean Momentum'
            'Mean Velocity'
            'Theoretical Kinetic Energy'
            'Initial Kinetic Energy'
            'Final Kinetic Energy'
            'Potential Energy'
            'Total Energy'
            'Position Uncertainty'
            'Momentum Uncertainty'
            'Uncertainty Product'
            'hbar / 2'};

        value = {
            lastResults.PotentialType
            lastResults.Nx
            lastResults.NtRequested
            lastResults.NtCompleted
            lastResults.DomainLength_nm
            lastResults.Wavelength_nm
            lastResults.PacketWidth_nm
            lastResults.InitialPositionFraction
            lastResults.PotentialHeight_eV
            lastResults.BarrierWidth_nm
            lastResults.WellWidth_nm
            lastResults.TimeStep_s
            lastResults.FinalSimulationTime_s
            lastResults.TotalProbability
            lastResults.Reflection
            lastResults.Transmission
            lastResults.InteractionProbability
            lastResults.CentralWellProbability
            lastResults.MeanPosition_nm
            lastResults.MeanMomentum
            lastResults.MeanVelocity
            lastResults.TheoreticalKE_eV
            lastResults.InitialKE_eV
            lastResults.FinalKE_eV
            lastResults.PotentialEnergy_eV
            lastResults.TotalEnergy_eV
            lastResults.PositionUncertainty_m
            lastResults.MomentumUncertainty
            lastResults.UncertaintyProduct
            lastResults.HbarOver2};

        unit = {
            ''
            ''
            ''
            ''
            'nm'
            'nm'
            'nm'
            ''
            'eV'
            'nm'
            'nm'
            's'
            's'
            ''
            ''
            ''
            ''
            ''
            'nm'
            'kg m/s'
            'm/s'
            'eV'
            'eV'
            'eV'
            'eV'
            'eV'
            'm'
            'kg m/s'
            'kg m^2/s'
            'kg m^2/s'};

        summaryTable = table(quantity,value,unit, ...
            'VariableNames',{'Physical_Quantity','Value','Unit'});

        writetable(summaryTable,fullfile(exportFolder, ...
            ['QuantumWavepacket_Summary_' stamp '.csv']));

        % Final wavepacket CSV
        waveTable = table( ...
            lastX(:)*1e9, ...
            lastYReal(:), ...
            lastYImag(:), ...
            lastDensity(:), ...
            lastPotential(:), ...
            'VariableNames',{ ...
            'Position_nm', ...
            'Real_Wavefunction', ...
            'Imaginary_Wavefunction', ...
            'ProbabilityDensity', ...
            'PotentialEnergy_eV'});

        writetable(waveTable,fullfile(exportFolder, ...
            ['Wavepacket_Final_Data_' stamp '.csv']));

        % Time-history CSV
        historyTable = table( ...
            lastStepHistory(:), ...
            lastTimeHistory(:), ...
            lastProbHistory(:), ...
            lastXMeanHistory(:)*1e9, ...
            lastKHistory(:), ...
            lastUHistory(:), ...
            lastEHistory(:), ...
            lastRHistory(:), ...
            lastTHistory(:), ...
            lastIHistory(:), ...
            lastWellHistory(:), ...
            'VariableNames',{ ...
            'TimeStep', ...
            'Time_s', ...
            'TotalProbability', ...
            'MeanPosition_nm', ...
            'KineticEnergy_eV', ...
            'PotentialEnergy_eV', ...
            'TotalEnergy_eV', ...
            'Reflection', ...
            'Transmission', ...
            'InteractionProbability', ...
            'CentralWellProbability'});

        writetable(historyTable,fullfile(exportFolder, ...
            ['Time_History_' stamp '.csv']));

        % MAT file
        savedResults = lastResults;
        savedX = lastX;
        savedYReal = lastYReal;
        savedYImag = lastYImag;
        savedDensity = lastDensity;
        savedPotential = lastPotential;
        savedTimeHistory = lastTimeHistory;
        savedDensityHistory = lastDensityHistory;
        savedProbHistory = lastProbHistory;
        savedXMeanHistory = lastXMeanHistory;
        savedKHistory = lastKHistory;
        savedUHistory = lastUHistory;
        savedEHistory = lastEHistory;
        savedStepHistory = lastStepHistory;
        savedRHistory = lastRHistory;
        savedTHistory = lastTHistory;
        savedIHistory = lastIHistory;
        savedWellHistory = lastWellHistory;

        save(fullfile(exportFolder,['QuantumWavepacket_Data_' stamp '.mat']), ...
            'savedResults', ...
            'savedX','savedYReal','savedYImag','savedDensity','savedPotential', ...
            'savedTimeHistory','savedDensityHistory','savedProbHistory', ...
            'savedXMeanHistory','savedKHistory','savedUHistory','savedEHistory', ...
            'savedStepHistory','savedRHistory','savedTHistory', ...
            'savedIHistory','savedWellHistory');

        uialert(fig,sprintf( ...
            ['Simulation results exported successfully.\n\n' ...
             'GUI: PDF + PNG\n' ...
             'Plots: 300 dpi PNG\n' ...
             'Numerical data: CSV\n' ...
             'Complete MATLAB data: MAT\n\n' ...
             'Location:\n%s'],exportFolder), ...
            'Export Complete');
    end

%% =======================================================================
% POTENTIAL CONTROL STATE
% ========================================================================
    function potentialChanged(~,~)
        potentialInfoLabel.Text = potentialDescription(potentialDrop.Value);

        switch potentialDrop.Value
            case 'Free Particle'
                U0Field.Enable = 'off';
                centreField.Enable = 'off';
                barrierWidthField.Enable = 'off';
                wellWidthField.Enable = 'off';

            case 'Potential Step'
                U0Field.Enable = 'on';
                U0Field.Value = -600;
                centreField.Enable = 'off';
                barrierWidthField.Enable = 'off';
                wellWidthField.Enable = 'off';

            case 'Linear Electric Field'
                U0Field.Enable = 'on';
                U0Field.Value = -600;
                centreField.Enable = 'off';
                barrierWidthField.Enable = 'off';
                wellWidthField.Enable = 'off';

            case 'Single Rectangular Hill / Well'
                U0Field.Enable = 'on';
                U0Field.Value = -600;
                centreField.Enable = 'off';
                barrierWidthField.Enable = 'off';
                wellWidthField.Enable = 'off';

            case 'Parabolic Well'
                U0Field.Enable = 'on';
                U0Field.Value = -600;
                centreField.Enable = 'off';
                barrierWidthField.Enable = 'off';
                wellWidthField.Enable = 'off';

            case 'Double Barrier'
                % Exact source-aligned case 6 values.
                U0Field.Enable = 'off';
                U0Field.Value = 62;
                centreField.Enable = 'off';
                centreField.Value = 0.50;

                % Display physical widths corresponding to source grid counts
                % for default Nx=1001, L=4 nm. Actual construction is grid-based.
                barrierWidthField.Enable = 'off';
                barrierWidthField.Value = 0.072;

                wellWidthField.Enable = 'off';
                wellWidthField.Value = 0.280;
        end
    end

%% =======================================================================
% SIMPSON'S 1/3 RULE
% ========================================================================
    function integral = simpsonGUI(f,a,b)
        N = length(f);

        if mod(N,2)~=1
            error('Simpson integration requires an odd number of data points.');
        end

        sc = 2*ones(N,1);
        sc(2:2:N-1)=4;
        sc(1)=1;
        sc(N)=1;

        hStep = (b-a)/(N-1);
        integral = (hStep/3)*(f*sc);
    end

%% =======================================================================
% REGIONAL INTEGRATION
% ========================================================================
    function result = integrateRegion(f,index,xgrid)
        if isempty(index)
            result = 0;
            return
        end

        fr = f(index);
        xr = xgrid(index);

        if length(fr)<2
            result = 0;
            return
        end

        if mod(length(fr),2)==1 && length(fr)>=3
            result = simpsonGUI(fr,xr(1),xr(end));
        else
            % For a selected physical region with an even number of samples,
            % use trapezoidal integration rather than discarding a grid point.
            result = trapz(xr,fr);
        end
    end

%% =======================================================================
% TRANSPORT PROBABILITIES
% ========================================================================
    function [R,T,Pinteraction,Pwell,applicable] = ...
            transportProbabilities(density,xgrid,potentialName,xL,xR,wLft,wRgt)

        R = NaN;
        T = NaN;
        Pinteraction = NaN;
        Pwell = NaN;
        applicable = false;

        switch potentialName

            case 'Potential Step'
                leftIndex = find(xgrid<xL);
                rightIndex = find(xgrid>=xL);

                R = integrateRegion(density,leftIndex,xgrid);
                T = integrateRegion(density,rightIndex,xgrid);
                Pinteraction = 0;
                applicable = true;

            case 'Single Rectangular Hill / Well'
                leftIndex = find(xgrid<xL);
                interactionIndex = find(xgrid>=xL & xgrid<=xR);
                rightIndex = find(xgrid>xR);

                R = integrateRegion(density,leftIndex,xgrid);
                Pinteraction = integrateRegion(density,interactionIndex,xgrid);
                T = integrateRegion(density,rightIndex,xgrid);
                applicable = true;

            case 'Double Barrier'
                leftIndex = find(xgrid<xL);
                interactionIndex = find(xgrid>=xL & xgrid<=xR);
                rightIndex = find(xgrid>xR);
                wellIndex = find(xgrid>=wLft & xgrid<=wRgt);

                R = integrateRegion(density,leftIndex,xgrid);
                Pinteraction = integrateRegion(density,interactionIndex,xgrid);
                T = integrateRegion(density,rightIndex,xgrid);
                Pwell = integrateRegion(density,wellIndex,xgrid);
                applicable = true;

            otherwise
                % R/T are intentionally N/A for Free Particle,
                % Linear Electric Field and Parabolic Well.
                applicable = false;
        end
    end

%% =======================================================================
% KINETIC ENERGY
% ========================================================================
    function Kavg = calculateKineticEnergy(yR,yI,C3eV,Llocal,Nlocal)
        fK = zeros(1,Nlocal);

        for ii=2:Nlocal-1
            fK(ii) = C3eV*(yR(ii)-1i*yI(ii))* ...
                (yR(ii+1)-2*yR(ii)+yR(ii-1) + ...
                 1i*(yI(ii+1)-2*yI(ii)+yI(ii-1)));
        end

        Kavg = simpsonGUI(fK,0,Llocal);
    end

%% =======================================================================
% MOMENTUM AND <p^2>
% ========================================================================
    function [pavg,p2avg] = calculateMomentum(yR,yI,dx,hbar,Llocal,Nlocal)

        dyRdx = zeros(1,Nlocal);
        dyIdx = zeros(1,Nlocal);

        dyRdx(1) = (yR(2)-yR(1))/dx;
        dyRdx(end) = (yR(end)-yR(end-1))/dx;
        dyIdx(1) = (yI(2)-yI(1))/dx;
        dyIdx(end) = (yI(end)-yI(end-1))/dx;

        for ii=2:Nlocal-1
            dyRdx(ii) = (yR(ii+1)-yR(ii-1))/(2*dx);
            dyIdx(ii) = (yI(ii+1)-yI(ii-1))/(2*dx);
        end

        % <p> = integral psi* (-i hbar d/dx) psi dx
        fp = -hbar.*( ...
            yI.*dyRdx - yR.*dyIdx + ...
            1i.*yR.*dyRdx + 1i.*yI.*dyIdx);

        pavg = simpsonGUI(fp,0,Llocal);

        % <p^2> = integral psi* (-hbar^2 d^2/dx^2) psi dx
        Cp2 = -hbar^2/dx^2;
        fp2 = zeros(1,Nlocal);

        for ii=2:Nlocal-1
            fp2(ii) = Cp2*(yR(ii)-1i*yI(ii))* ...
                (yR(ii+1)-2*yR(ii)+yR(ii-1) + ...
                 1i*(yI(ii+1)-2*yI(ii)+yI(ii-1)));
        end

        p2avg = simpsonGUI(fp2,0,Llocal);
    end

%% =======================================================================
% SECTION LABEL
% ========================================================================
    function sectionLabel(parent,textValue)
        lab = uilabel(parent, ...
            'Text',textValue, ...
            'FontWeight','bold', ...
            'FontColor',C.section);
        lab.Layout.Column = [1 2];
    end

%% =======================================================================
% COMPACT DASHBOARD CARD
% ========================================================================
    function valueLabel = createDashboardCard(parent,titleText,valueText)
        p = uipanel(parent, ...
            'BackgroundColor',[1 1 1], ...
            'BorderType','line', ...
            'HighlightColor',[0.80 0.84 0.90]);

        g = uigridlayout(p,[2 1]);
        g.RowHeight = {18,'1x'};
        g.Padding = [5 3 5 3];
        g.RowSpacing = 0;

        uilabel(g, ...
            'Text',titleText, ...
            'FontSize',8, ...
            'FontWeight','bold', ...
            'FontColor',C.section, ...
            'HorizontalAlignment','center');

        valueLabel = uilabel(g, ...
            'Text',valueText, ...
            'FontSize',12, ...
            'FontWeight','bold', ...
            'FontColor',[0.08 0.10 0.14], ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','center');
    end

%% =======================================================================
% OUTPUT BOX
% ========================================================================
    function valueLabel = createOutputBox(parent,titleText,valueText)
        p = uipanel(parent, ...
            'BackgroundColor',[0.97 0.985 1]);
        p.Layout.Column = [1 2];

        g = uigridlayout(p,[2 1]);
        g.RowHeight = {18,'1x'};
        g.Padding = [3 2 3 2];

        uilabel(g, ...
            'Text',titleText, ...
            'FontSize',9, ...
            'FontWeight','bold', ...
            'FontColor',C.section, ...
            'HorizontalAlignment','center');

        valueLabel = uilabel(g, ...
            'Text',valueText, ...
            'FontSize',12, ...
            'FontWeight','bold', ...
            'HorizontalAlignment','center');
    end

%% =======================================================================
% POTENTIAL DESCRIPTION
% ========================================================================
    function txt = potentialDescription(name)
        switch name
            case 'Free Particle'
                txt = ['Source case 1: U(x)=0. Free wavepacket propagation. ' ...
                    'Barrier-defined R and T are N/A.'];

            case 'Potential Step'
                txt = ['Source case 2: potential step beginning at the centre of the domain. ' ...
                    'The sign and magnitude are set by U0.'];

            case 'Linear Electric Field'
                txt = ['Source case 3: U(x)=-(U0/L)x+U0. ' ...
                    'This reproduces the accelerating/retarding linear potential.'];

            case 'Single Rectangular Hill / Well'
                txt = ['Source case 4: finite rectangular region. ' ...
                    'U0>0 gives a hill/barrier and U0<0 gives a well.'];

            case 'Parabolic Well'
                txt = ['Source case 5: U(x)=a x^2+b x with minimum -|U0| at x=L/2.'];

            case 'Double Barrier'
                txt = ['Source-aligned case 6: two +62 eV barriers, each 18 grid points wide, ' ...
                    'separated by a 70-grid-point central well.'];
        end
    end

%% =======================================================================
% POTENTIAL MARKERS
% ========================================================================
    function addPotentialMarkers(ax,name,xL,xR,b1L,b1R,wLft,wRgt,b2L,b2R)
        hold(ax,'on');

        switch name
            case 'Potential Step'
                xline(ax,xL*1e9,'--','x_s');

            case 'Single Rectangular Hill / Well'
                xline(ax,xL*1e9,'--','x_1');
                xline(ax,xR*1e9,'--','x_2');

            case 'Double Barrier'
                xline(ax,b1L*1e9,'--','x_1');
                xline(ax,b1R*1e9,'--','x_2');
                xline(ax,wRgt*1e9,'--','x_3');
                xline(ax,b2R*1e9,'--','x_4');
                % wLft equals b1R and b2L equals wRgt by construction.
        end

        hold(ax,'off');
    end

%% =======================================================================
% INVALID GEOMETRY HELPER
% ========================================================================
    function invalidGeometry(messageText)
        uialert(fig,messageText,'Invalid Potential Geometry');
        runButton.Enable = 'on';
        statusLabel.Text = 'Ready';
    end

end
