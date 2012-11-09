function [CSX, port] = AddLumpedPort( CSX, prio, portnr, R, start, stop, dir, excite, varargin )
% [CSX, port] = AddLumpedPort( CSX, prio, portnr, R, start, stop, dir, excite, varargin )
%
% Add a 3D lumped port as an excitation.
%
% CSX:      CSX-object created by InitCSX()
% prio:     priority for substrate and probe boxes
% portnr:   (integer) number of the port
% R:        internal resistance of the port
% start:    3D start rowvector for port definition
% stop:     3D end rowvector for port definition
% dir:      direction/amplitude of port (e.g.: [1 0 0], [0 1 0] or [0 0 1])
% excite (optional): if true, the port will be switched on (see AddExcitation())
%                       Note: for legacy support a string will be accepted
% varargin (optional): additional excitations options, see also AddExcitation
%
% example:
%   start = [-0.1 -width/2 0];
%   stop  = [ 0.1  width/2 height];
%   [CSX] = AddLumpedPort(CSX, 5 ,1 , 50, start, stop, [0 0 1], 'excite');
%   this defines a lumped port in z-direction (dir)
%
% openEMS matlab interface
% -----------------------
% Sebastian Held <sebastian.held@gmx.de>
% Jun 1 2010
% Thorsten Liebig
% Jul 13 2011
%
% See also InitCSX AddExcitation

% check dir

port.type='Lumped';
port.nr=portnr;

if (dir(1)~=0) && (dir(2) == 0) && (dir(3)==0)
    n_dir = 1;
elseif (dir(1)==0) && (dir(2) ~= 0) && (dir(3)==0)
    n_dir = 2;
elseif (dir(1)==0) && (dir(2) == 0) && (dir(3)~=0)
    n_dir = 3;
else
	error 'dir must have exactly one component ~= 0'
end

if (sum(start==stop)>0)
    error 'start/stop in must not be equal in any direction --> lumped port needs a 3D box'
end

if (stop(n_dir)-start(n_dir)) > 0
    direction = +1;
else
    direction = -1;
end
port.direction = direction;

port.Feed_R = R;
if (R>0 && (~isinf(R)))
    CSX = AddLumpedElement(CSX,['port_resist_' int2str(portnr)],  n_dir-1, 'Caps', 1, 'R', R);
    CSX = AddBox(CSX,['port_resist_' int2str(portnr)], prio, start, stop);
elseif (R<=0)
    CSX = AddMetal(CSX,['port_resist_' int2str(portnr)]);
    CSX = AddBox(CSX,['port_resist_' int2str(portnr)], prio, start, stop);
end

if (nargin < 8)
    excite = false;
end

% legacy support, will be removed at some point
if ischar(excite)
    warning('CSXCAD:AddLumpedPort','depreceated: a string as excite option is no longer supported and will be removed in the future, please use true or false');
    if ~isempty(excite)
        excite = true;
    else
        excite = false;
    end
end

port.excite = excite;
% create excitation
if (excite)
    CSX = AddExcitation( CSX, ['port_excite_' num2str(portnr)], 0, -dir*direction, varargin{:});
	CSX = AddBox( CSX, ['port_excite_' num2str(portnr)], prio, start, stop );
end

u_start = 0.5*(start + stop);
u_stop  = 0.5*(start + stop);
u_start(n_dir) = start(n_dir);
u_stop(n_dir)  = stop(n_dir);

CSX = AddProbe(CSX,['port_ut' int2str(portnr)], 0, -direction);
CSX = AddBox(CSX,['port_ut' int2str(portnr)], prio, u_start, u_stop);

i_start = start;
i_stop  = stop;
i_start(n_dir) = 0.5*(start(n_dir)+stop(n_dir));
i_stop(n_dir)  = 0.5*(start(n_dir)+stop(n_dir));

CSX = AddProbe(CSX,['port_it' int2str(portnr)], 1, direction);
CSX = AddBox(CSX,['port_it' int2str(portnr)], prio, i_start, i_stop);

