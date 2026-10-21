# Web30 - sala social A/B

Candidate based on Web29 commit a20f2cd69669e86c9690dc2275b085b19326bac8. Adds authoritative room rules/bots/ready state, room-only bounded plain-text chat and bounded reactions. Existing racing rules and assets preserved; no dragon, workshop extension or new vehicle integration.

Protocol social_version=1 negotiated on join/welcome/state. Legacy clients receive compatible racing snapshots without new social events. New client hides social UI on legacy servers. Web29 has a pre-existing ShaderMaterial color assignment failure, also reproduced against its old server; Web30 fixes that line. APK0.2.4 resources tested on desktop against new server, not on Android hardware.

Web bundle game-af69bf3db0a5bb48.pck, SHA-256 af69bf3db0a5bb48e806551d792db8497d8a238d5c7d7e11e45678c52053b6f3, 18430192 bytes. Existing Godot4.5.1 JS/WASM preserved. Previous Web29 HTML/PCK retained. Runtime endpoint wss://minikarts-multiplayer.onrender.com.

Repository recovery ref: backup/pre-social-web30-20261021 at bbaa7916aba22dcdfc12369165f8520123e286f8. Active Render deployment must be recorded before deploy and restored if verification fails. Free plan and autoDeploy=false must remain unchanged.

Candidate preparation is not a public deployment or physical phone verification.
