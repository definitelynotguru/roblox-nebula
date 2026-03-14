# Nebula AI for Roblox Studio

An AI coding assistant plugin for Roblox Studio. Chat with an AI that understands your game's context and can insert Luau scripts directly into your project.

## What It Does

- Chat panel inside Roblox Studio
- AI generates Luau scripts based on your requests
- One-click script insertion into workspace
- Context-aware: sends selected instance info, hierarchy, and script source as context
- Optional API key for backend authentication

## Quick Start

### 1. Backend Setup

```bash
cd backend
cp .env.example .env
# Edit .env and add your OpenAI API key
npm install
npm start
```

Server runs on `http://localhost:3000` by default.

### 2. Expose with a Tunnel

Roblox `HttpService` cannot reach `localhost` directly. Use a tunnel:

```bash
# Pick one:
npx localtunnel --port 3000
# or
ngrok http 3000
# or
cloudflared tunnel --url http://localhost:3000
```

Copy the public HTTPS URL it gives you (e.g., `https://abc.loca.lt`).

### 3. Install the Plugin

**Option A: Manual install**
1. Open Roblox Studio
2. Go to Plugins tab > Plugins Folder (or find your local plugins directory)
3. Create a folder called `NebulaAI`
4. Copy `plugin/ServerScript.lua` into it as `main.lua`
5. Restart Studio

**Option B: From .rbxmx file** (if you package it)
1. Drag the .rbxmx file into Studio
2. It installs automatically

### 4. Configure

1. In Studio, go to Plugins tab > click "Nebula AI" button (toolbar)
2. The chat panel docks on the right side
3. Click the Settings gear icon
4. Enter your tunnel URL (e.g., `https://abc.loca.lt`)
5. If you set `PLUGIN_API_KEY` in `.env`, enter that too

### 5. Use It

1. Select an object in the Explorer or Viewport
2. Type a request like "Make this part spin" or "Create a leaderboard"
3. Click Send or press Enter
4. When the AI returns a script, click "Insert Script" to add it to your workspace

## Configuration

### Environment Variables (.env)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | Yes | - | Your OpenAI API key |
| `PORT` | No | 3000 | Server port |
| `PLUGIN_API_KEY` | No | - | Shared secret for plugin auth |
| `MODEL` | No | gpt-4o-mini | OpenAI model to use |

### Roblox Studio Settings

In Game Settings > Security:
- Check "Allow HTTP Requests"
- Add your tunnel URL to the allowed domains list

## API

### `POST /api/chat`

**Headers:**
- `Content-Type: application/json`
- `Authorization: Bearer <PLUGIN_API_KEY>` (if configured)

**Body:**
```json
{
  "message": "Make this part spin",
  "context": {
    "selected": {
      "Name": "Part",
      "ClassName": "Part",
      "Position": "0, 5, 0"
    },
    "hierarchy": [
      {"Name": "Workspace", "Children": ["Part", "SpawnLocation"]}
    ]
  },
  "history": [
    {"role": "user", "content": "previous message"},
    {"role": "assistant", "content": "previous reply"}
  ]
}
```

**Response:**
```json
{
  "reply": "Here is a script...",
  "script": "local part = script.Parent\nwhile true do\n  part.Rotation += Vector3.new(0, 1, 0)\n  task.wait()\nend",
  "model": "gpt-4o-mini"
}
```

### `GET /api/health`

Returns server status. Useful for testing connectivity from the plugin.

## Architecture

```
Roblox Studio Plugin (Luau UI)
        │
        ▼  HTTPS (tunnel)
Local Backend (localhost:3000)
        │
        ▼  HTTPS
OpenAI API
```

The backend extracts Lua code blocks from AI responses and returns them separately in the `script` field, making it easy for the plugin to insert them directly.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "HTTP requests not enabled" | Enable in Game Settings > Security |
| "Connection refused" | Make sure backend is running and tunnel is active |
| "URL not whitelisted" | Add your tunnel URL to the allowed domains list |
| Plugin button not showing | Restart Studio, check Output window for errors |
| AI returns no script | Try being more specific: "Write a Luau script that..." |
| Tunnel URL changes | Update it in plugin settings (click gear icon) |

## Customization

### Change the AI Model

Edit `backend/server.js` or set the `MODEL` env var:
```
MODEL=gpt-4o          # Better quality, higher cost
MODEL=gpt-4o-mini     # Good balance (default)
MODEL=gpt-3.5-turbo   # Cheapest
```

### Add System Prompts

Edit the `SYSTEM_PROMPT` in `backend/server.js` to customize the AI's personality, expertise, or coding style.

### Styling

Edit the `THEME` table in the plugin Lua file to change colors.

## License

MIT