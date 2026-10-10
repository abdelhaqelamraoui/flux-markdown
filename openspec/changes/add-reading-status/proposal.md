# Change: Reading status in the existing toolbar

## Why
The empty space left of the native tools can orient readers without consuming more document height.

## What Changes
- Show the current heading path (last two levels), with the full path on hover.
- Show scroll progress for scrollable documents, labelled as position rather than proof of reading.
- Show the filename in QuickLook and a temporary notice after content updates.
- Fit available space, dropping filename, ancestors and progress before the current heading; hide entirely when the native tools leave insufficient room.

## Impact
Renderer toolbar, outline tracking and native render options. No additional dependencies or stored preferences.

## Authorization
The user approved this plan in conversation on 2026-10-10 and requested implementation. Optional detail statistics, reading-time estimates and breadcrumb navigation remain deferred.
