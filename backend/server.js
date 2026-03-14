require('dotenv').config();
const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');

const app = express();
const port = process.env.PORT || 3000;

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const MODEL = process.env.MODEL || 'gpt-4o-mini';
const API_KEY = process.env.PLUGIN_API_KEY || null;

app.use(cors());
app.use(express.json());

// Auth middleware (optional)
function authMiddleware(req, res, next) {
  if (!API_KEY) return next();
  const auth = req.headers.authorization;
  if (!auth || auth !== `Bearer ${API_KEY}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

const SYSTEM_PROMPT = `You are an expert Roblox Luau scripting assistant embedded in Roblox Studio.

Rules:
- Write clean, idiomatic Luau code
- Use modern Luau features (task library, type annotations where helpful)
- Always use task.wait() instead of wait()
- Prefer local variables
- Include brief comments explaining non-obvious logic
- When the user references selected objects, use them directly (script.Parent, etc.)
- Return complete, ready-to-run scripts
- Wrap your code in \`\`\`lua code blocks

Keep explanations brief. Lead with the code, then a short explanation of what it does.`;

function extractLuaCode(text) {
  const match = text.match(/```lua?\n?([\s\S]*?)```/);
  return match ? match[1].trim() : null;
}

function buildContextString(context) {
  if (!context) return '';
  let parts = [];

  if (context.selected) {
    const s = context.selected;
    parts.push(`## Selected Instance`);
    parts.push(`- Name: ${s.Name || 'Unknown'}`);
    parts.push(`- ClassName: ${s.ClassName || 'Unknown'}`);
    if (s.Position) parts.push(`- Position: ${s.Position}`);
    if (s.Size) parts.push(`- Size: ${s.Size}`);
    if (s.Parent) parts.push(`- Parent: ${s.Parent}`);
    if (s.Properties) {
      parts.push(`- Properties: ${JSON.stringify(s.Properties)}`);
    }
  }

  if (context.hierarchy && context.hierarchy.length > 0) {
    parts.push(`\n## Game Hierarchy (top-level):`);
    context.hierarchy.forEach(item => {
      parts.push(`- ${item.Name} (${item.ClassName || 'Folder'})`);
    });
  }

  if (context.script) {
    parts.push(`\n## Current Script Source:\n\`\`\`lua\n${context.script}\n\`\`\``);
  }

  if (context.errors && context.errors.length > 0) {
    parts.push(`\n## Recent Output/Errors:`);
    context.errors.forEach(err => parts.push(`- ${err}`));
  }

  return parts.join('\n');
}

app.post('/api/chat', authMiddleware, async (req, res) => {
  try {
    const { message, context, history } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    const messages = [
      { role: 'system', content: SYSTEM_PROMPT },
    ];

    // Add context if provided
    const contextString = buildContextString(context);
    if (contextString) {
      messages.push({
        role: 'system',
        content: `Current Studio Context:\n${contextString}`,
      });
    }

    // Add conversation history
    if (history && Array.isArray(history)) {
      history.forEach(msg => {
        if (msg.role && msg.content) {
          messages.push({ role: msg.role, content: msg.content });
        }
      });
    }

    // Add current message
    messages.push({ role: 'user', content: message });

    const completion = await openai.chat.completions.create({
      model: MODEL,
      messages,
      temperature: 0.7,
      max_tokens: 2048,
    });

    const reply = completion.choices[0].message.content;
    const script = extractLuaCode(reply);

    res.json({
      reply,
      script,
      model: MODEL,
    });
  } catch (error) {
    console.error('Chat error:', error.message);
    res.status(500).json({
      error: 'Failed to get AI response',
      details: error.message,
    });
  }
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', model: MODEL });
});

app.listen(port, () => {
  console.log(`Nebula AI backend running on http://localhost:${port}`);
  console.log(`Model: ${MODEL}`);
  console.log(`Auth: ${API_KEY ? 'enabled' : 'disabled'}`);
});