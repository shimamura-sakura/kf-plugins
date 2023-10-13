#include <sourcemod>

#define MODE_OFF	0
#define MODE_RAW	1
#define MODE_JUMP	2
#define MODE_COUNT	3

#define STAMINA_MAX 100.0
#define STAMINA_REC 19.0

int	 g_iShowStamina[MAXPLAYERS + 1];
char g_szModeNames[MODE_COUNT][] = {
	"off",
	"raw value and flRatio",
	"jump height and flRatio"
};
float  g_flJumpImpulse	  = 0.0;
float  g_flFrametimeRatio = 1.0;
ConVar sv_gravity;

public void OnPluginStart()
{
	for (int i = 0; i < MAXPLAYERS + 1; i++)
		g_iShowStamina[i] = 0;
	g_flJumpImpulse	   = SquareRoot(2 * 800 * 57.0);
	g_flFrametimeRatio = GetTickInterval() * 70.0;
	sv_gravity		   = FindConVar("sv_gravity");
	PrintToServer("[KF] sv_gravity = %f", sv_gravity.FloatValue);
	RegConsoleCmd("sm_stam", Cmd_ShowStamina, "Show stamina at health and armor");
	RegConsoleCmd("sm_showstamina", Cmd_ShowStamina, "Show stamina at health and armor");
}

public void OnClientPutInServer(int client)
{
	g_iShowStamina[client] = 0;
}

public Action Cmd_ShowStamina(int client, int argc)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[KF] not a server command");
		return Plugin_Handled;
	}
	int k = g_iShowStamina[client] = (g_iShowStamina[client] + 1) % MODE_COUNT;
	PrintToChat(client, "[KF] show stamina mode: %s", g_szModeNames[k]);
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsFakeClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	float stamina = GetEntPropFloat(client, Prop_Send, "m_flStamina");

	switch (g_iShowStamina[client])
	{
		case 0:
		{
			SetEntityHealth(client, 100);
			SetEntProp(client, Prop_Data, "m_ArmorValue", 0, 1);
		}
		case 1:
		{
			int	  floor	  = RoundToFloor(stamina);
			float flRatio = Pow((STAMINA_MAX - ((stamina / 1000.0) * STAMINA_REC)) / STAMINA_MAX, g_flFrametimeRatio);
			SetEntityHealth(client, floor <= 1 ? 1 : floor);
			SetEntProp(client, Prop_Data, "m_ArmorValue", RoundToFloor(flRatio * 100.0), 1);
		}
		case 2:
		{
			float flRatio = Pow((STAMINA_MAX - ((stamina / 1000.0) * STAMINA_REC)) / STAMINA_MAX, g_flFrametimeRatio);
			float gravity = sv_gravity.FloatValue * GetEntityGravity(client);
			float jumpImp = flRatio * g_flJumpImpulse;
			float jumpHei = jumpImp * jumpImp / 2 / gravity;
			SetEntityHealth(client, RoundToFloor(jumpHei));
			SetEntProp(client, Prop_Data, "m_ArmorValue", RoundToFloor(flRatio * 100.0), 1);
		}
	}

	return Plugin_Continue;
}