/*
 * Author: Titan
 * Event fired when unit killed
 *
 * Arguments:
 * 0: victim <OBJECT>
 * 1: attacker <OBJECT>
 * 2: instigator <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_victim, _attacker] call FUNC(eventKilled);
 *
 * Public: No
 */

#include "script_component.hpp"
private _functionLogName = "AAR > eventKilled";

params [
    ["_victim", objNull],
    ["_killer", objNull],
    ["_attacker", objNull]
];

if ( (GVAR(noPlayers) || !GVAR(logEvents)) && !(GVAR(forceLogEvents)) ) exitWith {};

// Handle respawnOnStart
if (_victim == objNull) exitWith {};

// UAV/UGV player operated road kill
if (isNull _attacker) then { _attacker = UAVControl vehicle _killer select 0 };
// Player driven vehicle road kill
if (isNull _attacker) then { _attacker = _killer };

// We only want to log ai or players being killed, not fences being run over!
if (
    (_attacker isEqualTo ObjNull) ||
    !(
        _victim isKindOf "CaManBase" ||
        _victim isKindOf "LandVehicle" ||
        _victim isKindOf "Air" ||
        _victim isKindOf "Ship" ||
        _victim isKindOf "Boat"
    )
) exitWith {};

private _entityVictim = _victim getVariable ["r3_entity_id", 0];

if (_entityVictim == 0) then {
    DBUG(format[ARR_2("Invalid victim: %1", _victim)], _functionLogName);
};

// Do we have the previous attacker stored against this unit from when they were
// knocked unconcious?
private _unconciousAttackerEntity = _victim getVariable ["attackerEntity", 0];

private _entityAttacker = _victim getVariable ["attackerEntity", 0];
private _attackerWeapon = _victim getVariable ["attackerWeapon", ''];
private _attackerDistance = _victim getVariable ["attackerDistance", ''];
private _sameFaction = _victim getVariable ["attackerSameFaction", 0];
private _attackerVehicle = _victim getVariable ["attackerVehicle", 0];

if !(_unconciousAttackerEntity isEqualTo 0) then {

    if (_victim == _attacker) then {
        _attacker = _victim getVariable ["lastAttacker", _victim];
    };

    private _formatedShotData = [_victim, _attacker] call FUNC(shotTemplate);

    _attackerWeapon = _formatedShotData select 0;
    _attackerDistance = _formatedShotData select 1;
    _entityAttacker = _attacker getVariable ["r3_entity_id", 0];

    _attackerVehicle = 0;
    if !(vehicle _attacker isEqualTo _attacker) then {
        _attackerVehicle = (vehicle _attacker) getVariable ["r3_entity_id", 0];
    };

    private _victimFaction = _victim call FUNC(calcSideInt);
    private _attackerFaction = _attacker call FUNC(calcSideInt);
    _sameFaction = 0;

    if (_victimFaction isEqualTo _attackerFaction) then {
        _sameFaction = 1;
    };
};

private _eventType = "killed";

private _data = [
    GVAR(missionId),
    round time,
    _eventType,
    _entityAttacker,
    _entityVictim,
    _attackerVehicle,
    _sameFaction,
    _attackerDistance,
    _attackerWeapon
];

// Send the data to the extension
private _saveData = GVAR(extensionName) callExtension ["events_downed", _data];
