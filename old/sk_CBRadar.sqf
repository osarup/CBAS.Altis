params ["_artyUnit", "_splashETA"];

_splashETA = floor (_splashETA);
_targetPos = _artyUnit getVariable ["CBR_targetPos", "000000"];
_splashGrid = mapGridPosition _targetPos;

//generate unique marker names for use with a specific artillery unit and corresponding grids
_artyNameString = str (_artyUnit);
_uniqueGridMarkerName = ("marker_arty_grid_" + _artyNameString);
_uniqueArtyMarkerName = ("marker_arty_" + _artyNameString); //for debug use

systemChat format ["ArtyMarker= %1, GridMarker= %2", _uniqueArtyMarkerName, _uniqueGridMarkerName];

//if unique grid marker for this unit doesn't already exist, create it
if !(_uniqueGridMarkerName in allMapMarkers) then {
	_marker = createMarkerLocal [_uniqueGridMarkerName, [0,0]];
	_marker setMarkerShapeLocal "RECTANGLE";
	_marker setMarkerColorLocal "colorOPFOR";
	_marker setMarkerBrushLocal "SOLID";
	_marker setMarkerAlphaLocal 0.5;
	_marker setMarkerSizeLocal [50,50];
};

//debug: track exact position for sanity
if !(_uniqueArtyMarkerName in allMapMarkers) then {
_markerVic = createMarkerLocal [_uniqueArtyMarkerName, _artyUnit];
_markerVic setMarkerTypeLocal "hd_dot";
_markerVic setMarkerTextLocal _artyNameString;
};

//get the grid position of the arty
_artyGridPos = mapGridPosition _artyUnit;
//systemChat _artyGridPos;
//transform grid to [x,y] and find centre
_realGridPosXY = [_artyGridPos select [0,3], _artyGridPos select [3,3]] apply {(parseNumber _x)*100 + 50};
systemChat str(_realGridPosXY);

["INCOMING FIRE ALERT!\n Tracking...Standby."] remoteExec ["hint"];

//draw markers after waiting for half the parabola
//arty may have moved by now
sleep (_splashETA/2);
[format ["INCOMING FIRE ALERT!\n Source Grid: %1\n Target grid: %2\n ETA: %3 seconds", _artyGridPos, _splashGrid, _splashETA/2]] remoteExec ["hint"];

_uniqueGridMarkerName setMarkerPos _realGridPosXY;
_uniqueArtyMarkerName setMarkerPos _artyUnit; //debug only
systemChat "CBRadar script complete";