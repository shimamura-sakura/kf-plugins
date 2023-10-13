#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
	RegConsoleCmd("sm_ent_id", Cmd_EntId);
}

float g_fPlayerSolidDist[MAXPLAYERS + 1];
int	  g_fHitEntity[MAXPLAYERS + 1];

public Action Cmd_EntId(int client, int argc)
{
	if (client == 0)
	{
		ReplyToCommand(client, "not a server command");
		return Plugin_Handled;
	}
	float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);
	TR_TraceRayFilter(pos, ang, MASK_SOLID, RayType_Infinite, Filter_RayDontHitSelf, client);
	if (TR_DidHit())
	{
		float beg[3], end[3];
		TR_GetStartPosition(INVALID_HANDLE, beg);
		TR_GetEndPosition(end, INVALID_HANDLE);
		g_fPlayerSolidDist[client] = GetVectorDistance(beg, end);
		PrintToChat(client, "[KF] dist %f", g_fPlayerSolidDist[client]);
	}
	else
		g_fPlayerSolidDist[client] = 1024.0;

	g_fHitEntity[client] = -1;
	TR_EnumerateEntities(pos, ang, PARTITION_NON_STATIC_EDICTS | PARTITION_SOLID_EDICTS | PARTITION_STATIC_PROPS | PARTITION_TRIGGER_EDICTS, RayType_Infinite, CB_EnumerateEntity, client);
	if (g_fHitEntity[client] == -1)
		PrintToChat(client, "[KF] no entity hit");
	return Plugin_Handled;
}

bool Filter_RayDontHitSelf(int entity, int contentsMask, int client)
{
	return entity != client;
}

public bool CB_EnumerateEntity(int entity, int client)
{
	if (entity < MaxClients)
		return true;
	Handle tr  = TR_ClipCurrentRayToEntityEx(MASK_ALL, entity);
	bool   hit = TR_DidHit(tr);
	if (hit)
	{
		float beg[3], end[3], dist;
		TR_GetStartPosition(tr, beg);
		TR_GetEndPosition(end, tr);
		dist = GetVectorDistance(beg, end);
		if (dist < g_fPlayerSolidDist[client])
		{
			char classname[256];
			GetEntityClassname(entity, classname, sizeof(classname));
			PrintToChat(client, "[KF] dist: %f entity: %d(%s)", dist, entity, classname);
			g_fHitEntity[client] = entity;
		}
	}
	CloseHandle(tr);
	return g_fHitEntity[client] == -1;
}