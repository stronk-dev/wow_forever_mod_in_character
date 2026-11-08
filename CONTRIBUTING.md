# Contributing

Small preset pull requests are welcome. Add only phrases you can attribute accurately; retain the supplied Stanley and Michael Nicht phrases verbatim. Do not generate new lines and label them as actual character quotations. Do not bundle ripped audio, images or whole transcripts. Preserve copyright/license notices for any reused code or assets.

To add a preset:

1. Copy `docs/PresetTemplate.lua.example` into `InCharacter/Data/Library/YourPack.lua` and fill in the metadata and lines. Choose a stable lowercase ASCII pack ID unique across the library. Use UTF-8 for sayings. Each line is plain text, never executable Lua or macro behavior.
2. Add `Data/Library/YourPack.lua` after `Services/Library.lua` in **both** TOCs, keeping them identical. Include meaningful source/episode details, speaker, locale, culture, author, content notes, and version. Cite a primary source when available. Distinguish owner-supplied lines, common expressions and independently checked quotations.
3. Run the checks below. The tests discover library modules from the TOC and validate each registration. Add focused tests if you change behavior.
4. Update the library catalogue, and describe exactly what changed and how you checked attribution. If changing existing pack content, increment its integer version; never change existing pack IDs or auto-update installed player copies.

```sh
lua tests/run.lua
lua tests/ui.lua
luajit tests/run.lua
luajit tests/ui.lua
python3 scripts/verify.py
python3 scripts/package.py
```

The runtime requires no dependencies. Tests use Lua (5.1-compatible syntax) and Python's standard library for manifest/packaging checks. CI runs Lua 5.1 and LuaJIT. Local development also checks Lua 5.5.1. Mocked UI tests verify callback/data behavior; they do not prove client API, rendering, input or chat restrictions. Use [FOREVER_TEST_CHECKLIST.md](FOREVER_TEST_CHECKLIST.md) for live-client changes and report the exact build tested.

Keep actions behind direct clicks, slash commands or bindings. Never add timed chat, combat automation, arbitrary slash/macro execution, `loadstring` imports, or updates that overwrite SavedVariables. UI layout rebuilds wait until combat ends; chat sends never wait in a queue.
