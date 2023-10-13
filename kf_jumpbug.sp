#include <sourcemod>
#include <sdktools_trace>

int g_iJumpBug[MAXPLAYERS + 1];
int g_bJumpBug[MAXPLAYERS + 1];

public void OnPluginStart()
{
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		g_iJumpBug[i] = -1;
		g_bJumpBug[i] = false;
	}
	RegConsoleCmd("sm_jb", Cmd_JumpBug, "[KF] try get a jumpbug in 200 ticks");
	RegConsoleCmd("sm_jumpbug", Cmd_JumpBug, "[KF] try get a jumpbug in 200 ticks");

	RegConsoleCmd("+jb", Cmd_ToggleJB, "[KF] try jumpbug when on");
	RegConsoleCmd("-jb", Cmd_ToggleJB, "[KF] try jumpbug when on");
	RegConsoleCmd("+jumpbug", Cmd_ToggleJB, "[KF] try jumpbug when on");
	RegConsoleCmd("-jumpbug", Cmd_ToggleJB, "[KF] try jumpbug when on");
}

public void OnClientPutInServer(int client)
{
	g_iJumpBug[client] = -1;
	g_bJumpBug[client] = false;
}

public Action Cmd_JumpBug(int client, int argc)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[KF] not a server command");
		return Plugin_Handled;
	}

	g_iJumpBug[client] = 200;
	if (argc > 0)
	{
		char arg[256];
		GetCmdArg(1, arg, sizeof(arg));
		g_iJumpBug[client] = StringToInt(arg);
	}

	PrintToChat(client, "[KF] will try a jumpbug in %d ticks", g_iJumpBug[client]);
	return Plugin_Handled;
}

public Action Cmd_ToggleJB(int client, int argc)
{
	char c[2];
	GetCmdArg(0, c, 2);
	g_bJumpBug[client] = c[0] == '+';
	PrintToChat(client, "[KF] jumpbug: %s", g_bJumpBug[client] ? "on" : "off");
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsFakeClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if (g_bJumpBug[client])
		g_iJumpBug[client] = 1;

	g_iJumpBug[client]--;
	if (g_iJumpBug[client] < 0)
		return Plugin_Continue;

	if (1
		&& GetEntityFlags(client) & FL_ONGROUND == 0
		&& (buttons & IN_DUCK))
	{
		float mins[3], maxs[3], start[3], end[3];
		GetClientMins(client, mins);
		GetClientMaxs(client, maxs);
		GetClientAbsOrigin(client, start);
		end[0]	   = start[0];
		end[1]	   = start[1];
		end[2]	   = start[2] - 11.0;
		start[2]   = start[2] - 9.0;
		Handle tr  = TR_TraceHullFilterEx(start, end, mins, maxs, MASK_PLAYERSOLID, Filter_RayDontHitSelf, client);
		bool   hit = TR_DidHit(tr);
		delete tr;

		if (hit)
		{
			buttons &= ~IN_DUCK;
			buttons |= IN_JUMP;
			g_iJumpBug[client] = -1;
			PrintToChat(client, "[KF] try jb !");
		}
	}

	return Plugin_Continue;
}

bool Filter_RayDontHitSelf(int entity, int contentsMask, int client)
{
	return entity != client;
}