# Nebula AI for Roblox Studio

Chat with Nebula here, get Luau scripts delivered straight into your Roblox Studio project.

## How It Works

```
You (in chat) -> Nebula generates code -> Posts to Discord -> Plugin picks it up -> Inserts into Studio
```

No tunnels, no backend servers, no localhost. Just a Discord bot watching a channel.

## Setup (5 minutes)

### 1. Create a Discord Bot

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **New Application**, name it something like "Nebula Studio"
3. Go to the **Bot** tab, click **Reset Token**, copy the token (you only see it once!)
4. Under **Bot** > **Privileged Gateway Intents**, enable:
   - Message Content Intent
5. Go to **OAuth2** > **URL Generator**:
   - Scopes: `bot`
   - Bot Permissions: `Send Messages`, `Read Message History`
6. Copy the generated URL, open it, invite the bot to your server

### 2. Create a Discord Channel

1. In your Discord server, create a text channel called `#roblox-studio`
2. Right-click the channel > **Copy Channel ID** (enable Developer Mode in Discord settings if needed)

### 3. Install the Plugin

1. Copy `plugin/ServerScript.lua` into your Studio plugins folder:
   - Windows: `%localappdata%/Roblox/Plugins/`
   - Mac: `~/Documents/Roblox/Plugins/`
2. Rename it to `NebulaAssistant.lua` (or any name you prefer)

### 4. Configure the Plugin

1. Open Roblox Studio - you should see a **Nebula AI** button in the toolbar
2. Click it to open the panel on the right
3. Enter your **Bot Token** and **Channel ID**
4. Click **Save Settings**
5. If Auto-refresh is ON, it starts polling immediately

### 5. Test It

Tell me something like:

> "Make a script that tweens a part upward when touched"

I'll post the code to your Discord channel, and the plugin will:
- Detect the snippet message
- Parse the Lua code
- Insert it as a new Script/LocalScript/ModuleScript in your workspace
- Open it in the script editor

## Usage

Just chat with me naturally. Examples:

- "Create a leaderboard system"
- "Write a door that opens on proximity"
- "Make a sprint script with stamina"
- "Build a inventory module with Add/Remove/Get methods"

I'll generate the code, post it to Discord, and your plugin picks it up automatically.

### Where Scripts Get Inserted

- If you have something selected in Explorer, the script goes there
- Otherwise, it goes into `Workspace`
- The script is automatically opened in the editor for you to review

### Snippet Format

Messages in the Discord channel use this structured format:

```json
{
  "type": "roblox_snippet",
  "version": "1",
  "title": "Door Proximity Script",
  "description": "Opens a door when a player gets close.",
  "script_type": "Script",
  "tags": ["door", "proximity"],
  "code": "local door = script.Parent\nlocal ProximityPrompt = door:FindFirstChild(\"ProximityPrompt\")\n-- ..."
}
```

You don't need to write this yourself - I handle it.

## Architecture

```
Nebula (cloud)
    |
    v  (Discord API - discord-send-message)
Discord Channel (#roblox-studio)
    |
    v  (Discord API - poll every 5s)
Roblox Studio Plugin (HttpService)
    |
    v
Script inserted into Explorer
```

- **Plugin** runs entirely in Studio using HttpService
- **Discord** is just the transport layer
- **No backend to host**, no ngrok, no tunnels
- Polls every 5 seconds for new snippet messages

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Plugin says "Invalid bot token" | Reset the token in Discord Developer Portal, paste the new one |
| "No access to channel" | Make sure the bot is invited to your server and has permission to read the channel |
| Scripts not appearing | Check that Auto-refresh is ON and the channel ID is correct |
| HttpService errors | Enable "Allow HTTP Requests" in Studio settings (Game Settings > Security) |
| Nothing happens when I ask you | I need to post to your Discord channel - make sure you've given me the channel info |

## Customization

### Poll Interval

The plugin polls every 5 seconds. To change it, edit `POLL_INTERVAL` at the top of the plugin file.

### Multiple Scripts

I can post multiple snippets in sequence. The plugin processes them in order.

### Undo

Use Ctrl+Z in Studio to undo an insertion.

## License

MIT - do whatever you want with it.