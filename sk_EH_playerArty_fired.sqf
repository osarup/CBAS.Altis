if !(isServer) exitWith {systemChat "EH_playerArty only to be run on server, exiting..."};

params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

/*
_paramArray = format ["unit = %1, weapon = %2, muzzle = %3, mode = %4, ammo = %5, magazine = %6, projectile = %7, gunner = %8", 
					_unit, _weapon, _muzzle, _mode, _ammo, _magazine, _projectile, _gunner];
copyToClipboard _paramArray;
systemChat _paramArray;
*/

/*
check if it indeed is the gunner firing firing the main gun
if coaxial artillery pieces exist then see alternative method below for more robust method. Doesn't seem to be the case.
currently unable to distinguish gunner using artillery computer or direct fire, both cases will evaluate true
*/

if (_gunner == gunner _unit && !isManualFire _unit) then {

	systemChat "artillery fired";
	
	//get grid and current firing time;
	_grid = mapGridPosition _unit;
	_time = serverTime;

	//systemChat format ["%1 , %2", _grid, _time];

	//send this info to the server;
	//missionNamespace setVariable ["playerArtyGrid", _grid, [2]];
	//missionNamespace setVariable ["playerArtyTime", _time, [2]];
	missionNamespace setVariable ["playerArtyGrid", _grid];
	missionNamespace setVariable ["playerArtyTime", _time];

} else {systemChat "other gun fired"};

/*
//alternatively
_magList = getArtilleryAmmo [_unit];
//check if one of these was fired
if (_magazine in _magList) then {systemChat "artillery fired"} else {systemChat "other gun fired"};
*/