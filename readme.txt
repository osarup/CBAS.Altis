INTRODUCTION:
This set of scripts adds a somewhat hacky counterbattery functionality to Arma 3. 
It runs an AI routine that fires at a provided target from designated waypoints and goes to rearm at another set of waypoints when valid supply vehicles are present.
When the AI fires, a counterbattery script is invoked that tells the players which grid the incoming fire originates and where the expected splash will be.
The AI will shoot and scoot, but the time taken to move is adjustable in the script (it's just sleep commands).
The players must react and counter this artillery. However, doing so reveals the player's grid as well (to imagined enemy counterbattery radar).
The enemy will prioritise shooting at player positions revealed within the specified time (by default 5 mins).

This leads to interesting artillery gameplay. The players must decide whether to fire their artillery in support of their infantry or to suppress enemy fire.
The artillery crew must figure out the pattern of the enemy. They cannot be static or will be hit in return.
UAV spotting will help hunt for the enemy or their resupply points. Maybe an SOF team goes behind enemy lines?

Note that this can be a pure SOF style infantry mission as well, without involving player artillery.
-----------------------------------------------------

SAMPLE RUN:
If using the sample mission, run script with params:
<here>
in either the artillery init field, trigger, initServer.sqf or debug console.
AI Artillery is controlled by sk_enemy_brain.sqf. This coordinates all the other AI scripts.
initServer.sqf adds the EHs for playable artillery uints (both BLUFOR and OPFOR).

----------------------------------------------------

FULL SETUP:

1. Player Artillery
In initServer.sqf, add the list of player artillery units to the Fired eventhandler that executes "sk_EH_playerArty_fired.sqf".
I used a gameLogic that's synced to each unit for convenience during development, but you can do it however you like (e.g. hardcoded array)
This will be the same for both co-op and PvP (or PvPvE).

1.a. PVP specific notes
Note that sk_EH_playerArty_fired.sqf will need to be modified to allow per side tracking, right now only tracks last player that fired.
sk_EH_CBRadar.sqf will also need to be modified to restrict hints to a side (or use sidechat).
sk_EH_CBRadar.sqf will need to be modified to work with player fired artillery, I leave that as an exercise to the reader.
Hint: if you modify sk_EH_playerArty_fired.sqf to track per side (or split the EH) then at the very least you could just pull that same info.

2. Enemy Artillery
Unit name is not required. Can name it if you invoke the script outside of the init field.
Do not exec this script more than once for one unit. It will stop automatically if either the vehicle is disabled or the gunner is killed.
I have not tried running this on multiple vehicles. It should work but be aware of performance considerations given these are scheduled scripts.
Most global vars specific to each unit are using the unit's namespace and not missionnamespace. Exceptions might have slipped through so best to check.

Artillery is controlled by sk_enemy_brain.sqf. You need to give it the artillery object, default target objects, a set of waypoints (gameLogic) to fire from and a set to rearm at.
it takes [object, object_array, string, string, optional_bool]. Strings are basically the var names of the first gameLogics of each series, but as a string.
e.g. "fire_wp" will automatically collect gamelogics called fire_wp, fire_wp_1, fire_wp_2, etc.
The last boolean is for randomization of waypoints, otherwise they will be followed in ascending order of naming.

2.a. sk_enemy_fireMission.sqf
You can adjust the nature of the fire mission inside sk_enemy_brain.sqf where the script sk_enemy_fireMission.sqf is run.
I would suggest setting a safezone if being used against player infantry, but no safezone for player artillery targets.
Alternatively, you can hardcode certain target locations and let it pick a random one. Useful if you don't want to accidently hit enemy AI attacking the players.

Also note that artillery may not be able to fire on certain slopes, but the script will handle this and proceed to the next fire waypoint.

3. Enemy artillery supply trucks/containers [sk_enemy_brain.sqf]
Near each rearm WP place an object that should serve as the ammo resupply vehicle. The idea is that this object can be destroyed by players to prevent resupply.
The ammo vehicles do not need to be named. Alternatively, you can name them in a series (just like the gamelogics) and provide the seed name in initServer.sqf.
You can also just use a manually hardcoded array, up to you. Automation is provided merely for convenience.
If you do not use such whitelist, however, then it will just look for Reammo_F or LandVehicle in a 25m radius near the rearm waypoint.
The whitelist can be useful if creating a logistics base or a vehicle protected by troops (e.g. for SOF mission).

There is no real restriction on what you decide is a resupply vehicle since the actual rearming is handled by the script.
By default it will look for an object of class Reammo_F or LandVehicle. The classes it checks for can be changed.
The class check happens in the rearm section of sk_enemy_brain.sqf and in initServer.sqf if a non-hardcoded whitelist is used.
If you use an actual resupply vehicle or container, be sure to setAmmoCargo to 0 either manually or via the editor init field.
Without setAmmoCargo, the AI automatically tries to rearm near a resupply vehicle, which can cause it to behave independently of the script.

4. sk_EH_CBRadar
The radar will by default send hints to everyone regarding the status of incoming shells, and will similarly mark the enemy position for everyone.
You can choose to adjust this (e.g. use sidechat instead, or only show it to artillery crew).
Note that as of now it does not show on the map where the target grid is. You may choose to do so to reduce burden on the players.
There is a debug marker that tracks the exact location of the artillery unit that fired. Remember to disable for a live mission!
x-------------------------------------------x

You should be good to go at this point.