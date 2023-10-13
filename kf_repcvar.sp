#include <sourcemod>

public void OnPluginStart()
{
	RegConsoleCmd("sm_repcvar", Cmd_RepCvar, "fake replicate convar");
}

public Action Cmd_RepCvar(int client, int argc)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[KF] not a server command");
		return Plugin_Handled;
	}

	if (argc < 2)
	{
		PrintToChat(client, "[KF] usage: command name value");
		return Plugin_Handled;
	}

	char name[64], value[256];
	GetCmdArg(1, name, sizeof(name));
	GetCmdArg(2, value, sizeof(value));
	ConVar cvar = FindConVar(name);

	if (cvar == null)
	{
		PrintToChat(client, "[KF] cvar not found");
		return Plugin_Handled;
	}

	bool result = cvar.ReplicateToClient(client, value);
	PrintToChat(client, "[KF] %s %s : %s", name, value, result ? "success" : "failed");

	return Plugin_Handled;
}