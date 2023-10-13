#include <sourcemod>
#include <sdktools>

bool g_bIsCSGO;

public void OnPluginStart()
{
	g_bIsCSGO = GetEngineVersion() == Engine_CSGO;
}

float getDuckAmount(int client)
{
	if (g_bIsCSGO)
	{
		return GetEntPropFloat(client, Prop_Send, "m_flDuckAmount");
	}
	else {
		return GetEntPropFloat(client, Prop_Send, "m_flDucktime") / 1000.0;
	}
}

bool Filter_RayDontHitSelf(int entity, int contentsMask, int client)
{
	return entity != client;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	static bool	 haveLastVel[MAXPLAYERS + 1];
	static float lastGroundVel[MAXPLAYERS + 1][3];

	if (IsFakeClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	bool bWalking = GetEntityMoveType(client) == MOVETYPE_WALK;
	if (!bWalking)
		return Plugin_Continue;

	bool bOnGround = (GetEntityFlags(client) & FL_ONGROUND) != 0;
	if (!bOnGround)
		return Plugin_Continue;

	bool bUnducked = (GetEntProp(client, Prop_Data, "m_afButtonReleased") & IN_DUCK) != 0;
	bool bDucking  = getDuckAmount(client) < 1.0;

	if (!(bUnducked && bDucking))
	{
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", lastGroundVel[client]);
		haveLastVel[client] = true;
		return Plugin_Continue;
	}

	float mins[3], maxs[3], start[3], end[3];
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	GetClientAbsOrigin(client, start);
	end[0]	   = start[0];
	end[1]	   = start[1];
	end[2]	   = start[2] + 40.0;
	Handle tr  = TR_TraceHullFilterEx(start, end, mins, maxs, MASK_PLAYERSOLID, Filter_RayDontHitSelf, client);
	bool   hit = TR_DidHit(tr);
	delete tr;

	if (hit)
		return Plugin_Continue;

	if (haveLastVel[client])
		TeleportEntity(client, end, NULL_VECTOR, lastGroundVel[client]);
	else {
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", lastGroundVel[client]);
		haveLastVel[client] = true;
		TeleportEntity(client, end);
	}

	return Plugin_Continue;
}