if !(isServer) exitWith {
	systemChat "ERROR: sk_enemy_fireMission.sqf not running on server";
	diag_log "ERROR: sk_enemy_fireMission.sqf not running on server";
};
/*
Documentation here
*/
params ["_artyUnit", "_targetPos", ["_magazine",""], ["_fireFullVolley", true], ["_burstSize", 8], ["_targetSafeZone",0], ["_targetRadius", 400]];

_tempEHindex = 0;

//create a hashmap of the magazines and ammo that the vehicle has
_magMap = createHashMapFromArray (magazinesAmmo [_artyUnit, true]);

//check if a mag has been specified, otherwise just use the first artillery mag the unit has.
if (_magazine == "") then {_magazine = ((keys _magMap) select 0)};

//read the available ammo count for the mag we're using
_magRounds = _magMap get _magazine;
if (_magRounds == 0) exitWith {systemChat "DEBUG: Vehicle has no ammo"};

//get ETA for rounds on target
//use this to check if the target is at a valid distance, if not, exit
_splashETA = _artyUnit getArtilleryETA [_targetPos, _magazine];
if (_splashETA < 1) exitWith {systemChat "DEBUG: Cannot fire, check distance from target"};

//by fire everything in one go unless specified, i.e. for loop runs once.
//also guard against potential divide-by-zero
if (_fireFullVolley || _burstSize <= 0) then {_burstSize = _magRounds};

for "_i" from 1 to ceil (_magRounds/_burstSize) do {

	systemChat "DEBUG: Starting fire mission loop, sleeping for 60s";

	//simulate artilley plot time. also gives time for players to read CB messages
	sleep 60; //60 default

	systemChat format ["DEBUG: Fire mission: Burst %1 of %2, firing %3 rounds", _i, ceil(_magRounds/_burstSize), _burstSize];

	//get fire position if safezone defined. min 50m otherwise it's mostly useless anyway.
	if (_targetSafeZone >= 50) then {
		_targetPos = [_targetPos, _targetSafeZone, _targetRadius, 0,0,0,0,[], _targetPos] call BIS_fnc_findSafePos;
	};

	//make sure that artillery is actually alive before starting fire mission.
	if !(alive _artyUnit) exitWith {systemChat "Enemy artillery destroyed"};

	//Add event handler that launches counter battery marker script.
	//Remove the EH first so that only the first shot of the burst is processed.
	_tempEHindex = _artyUnit addEventHandler ["Fired", {
			(_this select 0) removeEventHandler [_thisEvent, _thisEventHandler];
			_this execVM "sk_EH_CBRadar.sqf";
		}];
	
	_artyUnit setVariable ["CBR_targetPos", _targetPos]; //for EH access

	//fire at position with defined burst size
	_artyUnit doArtilleryFire [_targetPos, _magazine, _burstSize];

};

//wait until unit has fired or tried to fire (can fail on slopes)
waitUntil {sleep 2; unitReady _artyUnit};

//validate if artillery has actually fired
if (_magRounds > _artyUnit magazineTurretAmmo [_magazine, _artyUnit unitTurret (gunner _artyUnit)]) then {
	
	_artyUnit setVariable ["sk_enemyFireMission_success", true];
	systemChat "Fire mission script completed successfully";

} else {
	
	//remove the EH we added to avoid multiple EHs being stacked unecessarily
	_artyUnit removeEventHandler ["Fired",_tempEHindex];
	_artyUnit setVariable ["sk_enemyFireMission_success", false];
	systemChat "WARNING: Fire mission script completed unsuccessfully";
};