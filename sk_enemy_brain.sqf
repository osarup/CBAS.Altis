if !(isServer) exitWith {
	systemChat "ERROR: sk_enemy_brain.sqf not running on server";
	diag_log "ERROR: sk_enemy_brain.sqf not running on server";
};

//sleep in case run from init field to suspend until postinit.
sleep 1;

/*
input: artillery unit, default firing position, maybe the seed strings for waypoint collection.
build a list of positions to use as fire and rearm waypoints (two arrays) using ws_functions if there's no better way.
go to each one and either fire or rearm.

to fire:
use the input town position by default. provide a safePos to the firemission, along with safezones etc.
However, before firing on the town, check if the player artillery has fired. if it has, fire on that instead.
If player artillery position hasn't been updated in 10 mins, then fire on the town instead. You will have to compare serverTime for this.

to reload:
Assuming you're using trucks/containers in the editor, just wait for 120 seconds on each waypoint.
However, provide an alternative method using setMagazineTurretAmmo which loads in batches with some delay.

keep cycling through each array, but you must always rearm before firing.
*/

params [
			["_artyUnit", objNull, [objNull]],
			["_defaultTargetArray", [], [[]]],
			["_fire_wp_name", "", [""]],
			["_rearm_wp_name", "", [""]],
			["_randomWaypoints",false, [true]]
		];

//make sure params are vaid too, eg. if no arty provided, if no default target array, etc.
if (isNull _artyUnit) exitWith {systemChat "ERROR: artillery unit undefined (valid vehicle object name required)"};
if (count _defaultTargetArray > 0 && !(_defaultTargetArray isEqualTypeAll objNull)) exitWith {systemChat "ERROR: invalid default targets (need object array or empty array)"};
if (_fire_wp_name isEqualTo "") exitWith {systemChat "ERROR: fire waypoint series name has to be a string"};
if (_rearm_wp_name isEqualTo "") exitWith {systemChat "ERROR: rearm waypoint series name has to be a string"};

/*-------------------------WAYPOINT PREPROCESSING AND PREPARATION-------------------------------*/

//collect waypoint gamelogics in two arrays and sort them to make sure waypoints are in order.
_fire_wp_array = (entities "Logic") select {_fire_wp_name in str _x};
_rearm_wp_array = (entities "Logic") select {_rearm_wp_name in str _x};

if (_fire_wp_array isEqualTo []) exitWith {systemChat "ERROR: could not find objects matching fire wp series name"};
if (_rearm_wp_array isEqualTo []) exitWith {systemChat "ERROR: could not find objects matching rearm wp series name"};

//don't bother sorting if it's going to drive to random waypoints later anyway
if (!_randomWaypoints) then {
	
	_sortedArrays = [_fire_wp_array, _rearm_wp_array] apply {
		//convert gamelogics to strings
		_sortByArray = _x apply {str(_x)};
		//sort in ascending order
		_sortByArray sort true;
		//sort input array _x by the sorted list of strings in _sortByArray.
		//_input0 is a var available within BIS_fnc_sortBy and gets value of _sortByArray.
		//find (str _x) is iterating over the elements of the input array _x (fist param of function)
		//so wherever it finds the same string in _sortByArray, it orders the input array accordingly.
		[_x, [_sortByArray], {_input0 find (str _x)}] call BIS_fnc_sortBy;
	};

	_fire_wp_array = _sortedArrays select 0;
	_rearm_wp_array = _sortedArrays select 1;
};

//fetch and save a master array of magazines and ammo that the unit has
_artyUnit setVariable ["artyUnit_magazinesAmmo_array", magazinesAmmo [_artyUnit, true]];


/*----------------------------WAYPOINT CONTROL SECTION ----------------------------------------*/

//set initial wp (fire) and init vars
_currentWPtype = "fire";
_current_fire_wp_index = 0;
_current_rearm_wp_index = 0;

while {canMove _artyUnit && alive gunner _artyUnit} do{
//if !(alive _artyUnit) exitWith {systemChat "Enemy artillery destroyed"};


	//at each fire waypoint
	if (_currentWPtype == "fire") then 
	{

		systemChat "DEBUG: moving to fire waypoint";
		_handle = scriptNull;
		_currentWPpos = [];

		//set currentWP. check for randomization. IF random then no need to increment.
		if (_randomWaypoints) then 
		{
			_currentWPpos = getPos (selectRandom _fire_wp_array);
		} 
		else 
		{
			_currentWPpos = getPos (_fire_wp_array select _current_fire_wp_index);
			
			//increment or reset wp index
			if ((_current_fire_wp_index + 1) < (count _fire_wp_array)) then {
				_current_fire_wp_index = _current_fire_wp_index + 1} else {
					_current_fire_wp_index = 0;
			};
		};

		//now move.
		_artyUnit doMove _currentWPpos;
		//wait for arty to move to wp
		waitUntil {sleep 2; moveToCompleted _artyUnit};

		//check if players have fired, and if they fired within a certain time. default is 300s i.e. 5 mins
		_playerArtyGridVar = missionNamespace getVariable ["playerArtyGrid", ""]; //set in EH
		_playerArtyTimeVar = missionNamespace getVariable ["playerArtyTime", 0]; //set in EH

		//set fire mission success flag to false
		_artyUnit setVariable ["sk_enemyFireMission_success", false];

		if (_playerArtyGridVar != "" && {serverTime - _playerArtyTimeVar < 300}) then 
		{

			//transform grid to [x,y] and find centre
			_realGridPosXY = [_playerArtyGridVar select [0,3], _playerArtyGridVar select [3,3]] apply {(parseNumber _x)*100 + 50};
			//_realGridPosXY = _realGridPosXY apply {(parseNumber _x)*100 + 50};
			//systemChat str _realGridPosXY;

			_handle = [_artyUnit, _realGridPosXY] execVM "sk_enemy_fireMission.sqf";

		} 
		else 
		{
			if (_defaultTargetArray isEqualTo []) exitWith {"DEBUG: No default target provided, waiting for players to fire."};
			//select a random target from the provided array. (if just one then it'll always select that anyway)
			_defaultTargetObject = selectRandom _defaultTargetArray;
			//would not suggest using safezones with targets that are close together
			//for a single target, especially around infantry, highly recommended to use safezones.
			_handle = [_artyUnit, getPos _defaultTargetObject] execVM "sk_enemy_fireMission.sqf";
			//_handle = [_artyUnit, getPos _defaultTargetObject, "", false] execVM "sk_enemy_fireMission.sqf";
			//_handle = [_artyUnit, getPos _defaultTargetObject, "", false, 16, 300] execVM "sk_enemy_fireMission.sqf";
		};


		//wait until firemission script is done
		waitUntil {sleep 10; scriptDone _handle};

		//toggle next wp type if fire mission was successful
		if (_artyUnit getVariable ["sk_enemyFireMission_success", false]) then {
			_currentWPtype = "rearm";
		};
	
	} 
	else 
	{
		//at each rearm point
		if (_currentWPtype == "rearm") then {

			systemChat "DEBUG: moving to rearm waypoint";

			_currentWPpos = [];

			//set currentWP. check for randomization. IF random then no need to increment.
			if (_randomWaypoints) then 
			{
				_currentWPpos = getPos (selectRandom _rearm_wp_array);
			} 
			else 
			{
				_currentWPpos = getPos (_rearm_wp_array select _current_rearm_wp_index);
				
				//increment or reset wp index
				if ((_current_rearm_wp_index + 1) < (count _rearm_wp_array)) then {
					_current_rearm_wp_index = _current_rearm_wp_index + 1} else {
						_current_rearm_wp_index = 0;
				};
			};

			//now move.
			_artyUnit doMove _currentWPpos;
			//wait for arty to move to wp
			waitUntil {sleep 5; moveToCompleted _artyUnit};

			/*check if there's a supply vehicle or container nearObjectsReady that hasn't been destroyed
			by default just checks if there are ammo boxes or vehicles present 
			but you can make it more selective by providing a whitelist in initserver.sqf

			This checks for a true exit condition!
			
			Algo:
			get list of nearestObjects, select alive
			read the whitelist.
			check if there is 1 or less units nearby. because then there's either nothing alive or just the arty unit.
			(unit itself is always returned by nearestObjects, so if just one element then it's just the unit itself)
			In this case you will always exit since there's no chance of a resupply unit.
			OR if that is not the case (i.e. more than 1 unit is present) then we care about the whitelist.
			check if a whitelist was specified AND check if nothing from the whitelist is nearby, in which case exit.
			if there was no whitelist then just use default behaviour and assume any vehicle is a valid supply vehicle.

			Lazy eval used for a little performance boost and to avoid the arrayIntersect if possible, since 6/8 cases don't care about it.
			*/
			
			_aliveNearestVehicles = (nearestObjects [_artyUnit, ["ReammoBox_F", "LandVehicle"], 25]) select {alive _x};

			_ammoVehiclesWhitelist = missionNamespace getVariable ["sk_enemyResupplyTrucks",[]];

			//_aliveAmmoVehicles = _aliveNearestVehicles arrayIntersect _ammoVehiclesWhitelist;
			
			if (count _aliveNearestVehicles <= 1 || {
							count _ammoVehiclesWhitelist > 0 && {
								count (_aliveNearestVehicles arrayIntersect _ammoVehiclesWhitelist) == 0
							}
						}
			) exitWith {
				systemChat "WARNING: No valid resupply vehicle or container present, moving to next rearm WP";
			};

			//rearm the vehicle. this could be more complicated if you wanted but currently just replensishes all ammo
			//WARNING: use this setAmmoCargo 0; on all supply containers to avoid AI running off on its own to rearm 

			//both sleeps below are just to simulate plausible rearming times, but set to whatever you like
			systemChat "DEBUG: Starting rearm";
			sleep 60;
			//set all ammo to full.
			_artyUnit getVariable ["artyUnit_magazinesAmmo_array",[]] apply {
				_artyUnit setMagazineTurretAmmo [_x select 0, _x select 1, _artyUnit unitTurret (gunner _artyUnit)];
			};
			sleep 30;
			systemChat "DEBUG: Rearm completed";

			//toggle next wp type
			_currentWPtype = "fire";
		};
	};
};

systemChat "DEBUG AI brain script exited";

/*
------------------------------------------------------------------------------------------------------------------
OLD/ALT CODE

_fire_wp_array = (entities "Logic") select {(str _x) regexMatch (_fire_wp_name + "_?(\d?){2}")};

_fire_wp_array = (entities "Logic") select {_fire_wp_name in str _x};
_sortByArray = _fire_wp_array apply {str(_x)};
_sortByArray sort true;
_fire_wp_array = [_fire_wp_array, [_sortByArray], {_input0 find (str _x)}] call BIS_fnc_sortBy;
systemChat str _fire_wp_array;

_rearm_wp_array = (entities "Logic") select {_rearm_wp_name in str _x};
_sortByArray = _rearm_wp_array apply {str(_x)};
_sortByArray sort true;
_rearm_wp_array = [_rearm_wp_array, [_sortByArray], {_input0 find (str _x)}] call BIS_fnc_sortBy;
systemChat str _rearm_wp_array;
*/