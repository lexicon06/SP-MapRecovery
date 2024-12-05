#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

// Path to the map recovery file
char filePath[PLATFORM_MAX_PATH];
// Flag to indicate if the map has been recovered
bool hasRecovered = false;

// Plugin data information
public Plugin myinfo =
{
	name		= "Map Recovery",
	description = "Recovers the latest map when the Server crashed or was restarted. I Have made this for my own L4D2 server, so it may not work for everyone.",
	author		= "PabloSan",
	version		= "1.0",
	url		= "www.pablosan.dev"
};

/**
 * @summary Initializes the plugin and sets up the map recovery file.
 *
 * This function is called when the plugin starts. It builds the path to the map recovery file,
 * creates a ConVar for the plugin version, and checks if the map recovery file exists. If the file
 * does not exist, it creates the file and writes the current map name to it.
 */
public void OnPluginStart()
{
	BuildPath(Path_SM, filePath, sizeof(filePath), "configs/map_recover.txt");
	CreateConVar("sm_maprecovery_version", "1.0", "Map Recovery Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	if (!FileExists(filePath))
	{
		File dataFile = OpenFile(filePath, "w");
		if (dataFile != null)
		{
			char currentMap[PLATFORM_MAX_PATH];
			GetCurrentMap(currentMap, sizeof(currentMap));
			WriteFileLine(dataFile, currentMap);
			delete dataFile;
			hasRecovered = true;
		}
		else
		{
			LogError("[Map Recovery] Failed to create file '%s'", filePath);
		}
	}
}

/**
 * @summary Handles map start events and performs map recovery if necessary.
 *
 * This function is called when a new map starts. It gets the current map name,
 * reads the last saved map name from the recovery file, and compares the two.
 * If the current map matches the last saved map, it sets the recovery flag to true.
 * If the current map does not match the last saved map, it changes the map to the last saved map.
 */
public void OnMapStart()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	// Update the file with the current map
	if (hasRecovered)
	{
		File dataFile = OpenFile(filePath, "w");
		if (dataFile != null)
		{
			WriteFileLine(dataFile, currentMap);
			delete dataFile;
		}
		else
		{
			LogError("[Map Recovery] Failed to open file '%s' for writing", filePath);
		}
	}
	else
	{
		char lastMap[PLATFORM_MAX_PATH];
		File dataFile = OpenFile(filePath, "r");
		if (dataFile != null)
		{
			ReadFileLine(dataFile, lastMap, sizeof(lastMap));
			delete dataFile;

			// Trim any whitespace or newline characters just in case
			TrimString(lastMap);

			if (strcmp(currentMap, lastMap) == 0)
			{
				hasRecovered = true;
				LogMessage("[Map Recovery] Current map matches last saved map: %s", currentMap);
			}
			else
			{
				LogMessage("[Map Recovery] Changing map from %s to %s after possible crash!", currentMap, lastMap);
				ServerCommand("changelevel %s", lastMap);
			}
		}
		else
		{
			LogError("[Map Recovery] Failed to open file '%s' for reading", filePath);
		}
	}
}
