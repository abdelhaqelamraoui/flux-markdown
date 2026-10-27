# Usage statistics client contract

This repository contains the macOS client, its tests and public privacy disclosure.
The independently maintained ingestion service is not part of this repository.
See [Privacy](../PRIVACY.md) for collected fields, retention and opt-out behavior.

## Counters and transport

App and Quick Look share permission-protected cumulative counters keyed by UTC day,
app/macOS version and source. Each counter has a random bucket ID and monotonic
sequence. A visible successful opening counts once; rerendering does not. Reading
seconds estimate visible activity, excluding sleep and hidden-window gaps.

Dirty counters upload at most once per hour under a shared lease, with up to 50
buckets per batch and 90 days / 720 buckets retained locally. Acknowledgement marks
only the delivered sequence; concurrent new usage remains pending. Failed uploads
never block rendering. Opt-out clears unsent counters and rotates identity.

The public v3 HTTPS request sends integer Unix seconds for preparation time and UTC
day start, and optional batch-level IANA timezone. It excludes document contents,
paths, names, account identifiers and raw logs. Timezone is not verified location.

Quick Look persists counters and requests a parameterless flush through its
existing authenticated XPC helper. The helper reads state, checks opt-out and the
hourly lease, uploads to the fixed endpoint and persists acknowledgement. It does
not launch the main app or accept externally supplied URLs, payloads or paths.

## Verification

Client regression coverage remains in `Tests/MarkdownTests/UsageTelemetryTests.swift`.
Release entitlement checks verify the narrow Telemetry-directory write grant.
Historical combined client/server design and deployment evidence is maintained
with the independent backend; this document describes only the client contract.
