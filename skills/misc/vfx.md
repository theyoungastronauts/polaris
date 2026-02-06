---
name: VFX Platform Documentation
description: Fetch and reference VerifiedX platform documentation from GitHub. Use this when the user asks about VFX platform features, architecture, components (web-explorer/Spyglass, core services, web-api, browser extension, GUI, web-js-sdk, Trillium smart contracts), integration patterns, or needs context about the VerifiedX blockchain ecosystem.
---

# VFX Platform Documentation Skill

This skill fetches documentation from the VerifiedX Platform Context repository to provide comprehensive context about the VFX platform ecosystem.

## Repository Structure

The documentation is organized by component:
- `README.md` - Overview of the platform
- `web-explorer/` - Blockchain explorer (Spyglass) documentation
- `core/` - Core business logic and services
- `web-api/` - Backend API services
- `browser-extension/` - Browser extension
- `gui/` - Desktop interface application
- `web-js-sdk/` - JavaScript SDK
- `trillium/` - Smart contract language
- `landing-site/` - Marketing/product website

## How to Use This Skill

When the user asks about VFX platform features or needs context:

1. Determine which component(s) are relevant to the question
2. Use WebFetch to retrieve documentation from the raw GitHub URLs:
   - Main README: `https://raw.githubusercontent.com/VerifiedXBlockchain/VerifiedX-PlatformContext/main/README.md`
   - Component docs: `https://raw.githubusercontent.com/VerifiedXBlockchain/VerifiedX-PlatformContext/main/{component}/README.md`
   - Specific files: `https://raw.githubusercontent.com/VerifiedXBlockchain/VerifiedX-PlatformContext/main/{component}/{file}.md`

3. Use the fetched documentation to answer questions with accurate, contextual information

## Example Usage

If user asks about the Spyglass web explorer:
- Fetch: `https://raw.githubusercontent.com/VerifiedXBlockchain/VerifiedX-PlatformContext/main/web-explorer/README.md`

If user asks about the overall platform:
- Fetch: `https://raw.githubusercontent.com/VerifiedXBlockchain/VerifiedX-PlatformContext/main/README.md`

If user asks about API endpoints:
- Fetch: `https://raw.githubusercontent.com/VerifiedXBlockchain/VerifiedX-PlatformContext/main/web-api/README.md`

## Notes

- Always use the raw.githubusercontent.com URLs to fetch actual file content
- Start with the main README for general platform questions
- Navigate to specific component docs for detailed questions
- You can fetch multiple documentation files if the question spans multiple components
