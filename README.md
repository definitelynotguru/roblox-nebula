# Nebula AI for Roblox Studio

![GitHub License](https://img.shields.io/github/license/definitelynotguru/roblox-nebula?style=flat-square)
![GitHub Stars](https://img.shields.io/github/stars/definitelynotguru/roblox-nebula?style=flat-square)
![Roblox Studio](https://img.shields.io/badge/Roblox-Studio-blue?style=flat-square&logo=roblox)
![Discord](https://img.shields.io/badge/Discord-Channel-5865F2?style=flat-square&logo=discord&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-Scripts-000080?style=flat-square&logo=lua&logoColor=white)

Chat with Nebula, get Lua scripts delivered straight into your Roblox Studio project.

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

1. Copy `plugin/NebulaSnippetLoader.lua` into your Studio plugins folder:
   - Windows: `%localappdata%/Roblox/Plugins/`
   - Mac: `~/Documents/Roblox/Plugins/`
2. Open Roblox Studio -- you should see a **Nebula AI** button in the toolbar

### 4. Configure the Plugin

1. Click the **Nebula AI** button to open the panel
2. Enter your **Bot Token** and **Channel ID**
3. Click **Save Settings**
4. If Auto-refresh is ON, it starts polling immediately

### 5. Test It

Tell me something like:

> "Make a script that tweens a part upward when touched"

I'll post the code to your Discord channel, and the plugin will:
- Detect the snippet message
- Parse the Lua code
- Insert it as a new Script/LocalScript/ModuleScript in your workspace
- Open it in the script editor for you to review

## Usage

Just chat with me naturally. Examples:

- "Create a leaderboard system"
- "Write a door that opens on proximity"
- "Make a sprint script with stamina"
- "Build an inventory module with Add/Remove/Get methods"

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
  "code": "local door = script.Parent\n..."
}
```

You don't need to write this yourself -- I handle it.

### Available Snippets

Pre-built scripts you can grab instantly:

| Snippet | Description |
|---------|-------------|
| Day Night Cycle | Automatic sky lighting with configurable time speed |
| D20 Roll | Animated dice roller with nat 20/1 support |

Ask me for a snippet by name and I'll send it to your channel.

## Architecture

```
+-----------+     +-----------+     +-----------+
| Chat UI   |---->| Discord   |---->| Plugin    |
| (Nebula)  |     | Channel   |     | (Roblox)  |
+-----------+     +-----------+     +-----------+
      ^                                   |
      |          +-----------+            |
      +----------| GitHub    |<-----------+
                 | (storage) |
                 +-----------+
```

## License

MIT