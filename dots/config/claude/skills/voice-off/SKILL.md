---
name: voice-off
description: Stop voice conversation mode. Use when the user says "voice off", "stop voice", "stop talking" or "text only".
---

`/voicemode:converse` starts voice but has no stop command. This skill is the stop.

1. Stop calling the voicemode `converse` tool for the rest of the session.
2. If a turn is in flight, send one last `converse` call saying "Voice off." with `wait_for_response: false`.
3. Reply in text from then on.

This changes session behavior only. It does not touch `voicemode.env` or the Kokoro/Whisper services.
Voice stays off until the user runs `/voicemode:converse` or asks for voice explicitly.
