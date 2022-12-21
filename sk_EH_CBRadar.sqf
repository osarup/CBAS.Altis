if !(isServer) exitWith {systemChat "EH_CBRadar only to be run on server, exiting..."};

params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

_targetPos = _unit getVariable ["CBR_targetPos", "000000"]; //set in firemission script
_splashGrid = mapGridPosition _targetPos;
_splashETA = _unit getArtilleryETA [_targetPos, _magazine];

//generate unique marker names for use with a specific artillery unit and corresponding grids
_artyNameString = str (_unit);
_uniqueGridMarkerName = ("marker_arty_grid_" + _artyNameString);
//_uniqueArtyMarkerName = ("marker_arty_" + _artyNameString); //for debug use

//systemChat format ["ArtyMarker= %1, GridMarker= %2", _uniqueArtyMarkerName, _uniqueGridMarkerName];

//if unique grid marker for this unit doesn't already exist, create it
if !(_uniqueGridMarkerName in allMapMarkers) then {
	_marker = createMarkerLocal [_uniqueGridMarkerName, [0,0]];
	_marker setMarkerShapeLocal "RECTANGLE";
	_marker setMarkerColorLocal "colorOPFOR";
	_marker setMarkerBrushLocal "SOLID";
	_marker setMarkerAlphaLocal 0.5;
	_marker setMarkerSizeLocal [50,50];
};

/*debug: track exact position for sanity
if !(_uniqueArtyMarkerName in allMapMarkers) then {
_markerVic = createMarkerLocal [_uniqueArtyMarkerName, _unit];
_markerVic setMarkerTypeLocal "hd_dot";
_markerVic setMarkerTextLocal _artyNameString;
};*/

//get the grid position of the arty
_artyGridPos = mapGridPosition _unit;
//systemChat _artyGridPos;
["INCOMING FIRE ALERT!\n Tracking...Standby."] remoteExec ["hint"];

//transform grid to [x,y] and find centre
_realGridPosXY = [_artyGridPos select [0,3], _artyGridPos select [3,3]] apply {(parseNumber _x)*100 + 50};
systemChat str(_realGridPosXY);

//draw markers after waiting for half the parabola
//arty may have moved by now
sleep floor(_splashETA/2);
[format ["INCOMING FIRE ALERT!\n Source Grid: %1\n Target grid: %2\n ETA: %3 seconds", _artyGridPos, _splashGrid, floor(_splashETA/2)]] remoteExec ["hint"];

_uniqueGridMarkerName setMarkerPos _realGridPosXY;
//_uniqueArtyMarkerName setMarkerPos _unit; //debug only
systemChat "CBRadar script complete";