//add event handlers here.
{
	_x addEventHandler ["Fired", {_this execVM "sk_EH_playerArty_fired.sqf"}];
} forEach (synchronizedObjects sk_playerArty_EH_logic);

//-----------------------------------------------------------

//init ammo truck whitelist [optional] [only relevant for AI arty, disable for PvP]
//WARNING: if you don't use this feature, manually run 'this setAmmoCargo 0;' on all ammo vehicles via editor init field

//specify the name of the first vehicle in the series below
_ammoVehicleSeriesName = "ammoVehicle";
//Aletnatively, leave blank:
//_ammoVehicleSeriesName = "";

//check if above string is set
if (_ammoVehicleSeriesName isNotEqualTo "") then {
	
	//build a list of vehicles of that name
	_ammoVehicles =  (entities [["ReammoBox_F", "LandVehicle"],[],false,false]) select {_ammoVehicleSeriesName in str _x};
	
	//set a global vehicle for use by sk_enemy_brain.sqf
	missionNamespace setvariable ["sk_enemyResupplyTrucks",_ammoVehicles];
	
	//make sure they all have no ammo
	_ammoVehicles apply {_x setAmmoCargo 0};
};
//-------------------------------------------------------------
//END OF FILE