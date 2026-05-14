# Reference Workbench Skill

An agent skill that verifies academic citations and writes literature reviews with auto-generated bibliographies. Checks paper existence, metadata accuracy, and whether cited claims are actually supported. Compatible with Claude Code, Codex, Gemini CLI, Cursor, VS Code, and 20+ other editors that support the Agent Skills standard.

This skill merges and supersedes the former [citation-check-skill](https://github.com/haiyichen001/citation-check-skill) and [introduction-review-skill](https://github.com/haiyichen001/introduction-review-skill).

## What it does

| Feature | Description |
|---------|-------------|
| Citation verification | Checks existence, metadata, and content support for every citation |
| Literature review writing | Guided workflow for introductions and lit reviews with auto-numbered references |
| Reference table generation | Deterministic 5-column table: #, Author, Context, Reference, Status |
| Self-audit | Auto-checks stacking, format, order, orphans, and tone after every edit |
| Multi-format input | PDF, DOCX, TXT, Markdown, LaTeX |

## Install

### Universal (any agent)

Download and copy the skill folder into your agent's skills directory:

| Agent | Project scope | User scope |
|-------|--------------|------------|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.codex/skills/` | `~/.codex/skills/` |
| Gemini CLI | `.gemini/skills/` | `~/.gemini/skills/` |
| Cursor | `.cursor/skills/` | `~/.cursor/skills/` |
| VS Code / Copilot | `.github/skills/` | `~/.copilot/skills/` |

### CLI quick install

```bash
npx skills add haiyichen001/reference-workbench-skill
```

### Manual

```bash
git clone git@github.com:haiyichen001/reference-workbench-skill.git
cp -r reference-workbench-skill/.claude/skills/reference-workbench ~/.claude/skills/
```

### MCP dependencies

**Required:**

| Category | MCP | Purpose |
|----------|-----|---------|
| Search | arxiv | arXiv paper lookup |
| Search | scholar | Semantic Scholar verification |
| Search | paper-search | PubMed / bioRxiv / Google Scholar |
| Search | crossref | Crossref DOI + OpenAlex + Semantic Scholar |
| Tool | pdf-reader | PDF text extraction |

```bash
npx smithery install @smithery-ai/arxiv
npx smithery install @smithery-ai/scholar
npx smithery install @smithery-ai/paper-search
pip install crossref-academic-mcp-server
```

**Optional (enhanced workflow):**

| MCP | What it adds | Install |
|-----|-------------|---------|
| Zotero | Reference library integration — search your library, import papers, Word citations | `npx smithery install @alisoroushmd/zotero-mcp` |
| DeepL | Academic translation (中文 ↔ English), glossary-locked terminology | `npm install deepl-mcp-server` (free API key) |

## Usage

```
/reference-workbench
```

Two modes available:

1. **Check mode** — provide a file or paste text to verify all citations
2. **Write mode** — guided literature review writing with `[CITE:lastnameYEAR]` placeholders

### Verification statuses

| Status | Meaning |
|--------|---------|
| Verified | Paper exists, metadata correct, content supports the claim |
| Metadata Mismatch | Paper exists but author/year/venue differs |
| Content Mismatch | Paper exists but cited content does not support the claim |
| Fabricated | Paper does not exist — likely AI hallucination |
| Unverifiable | Insufficient data (e.g. Chinese thesis not indexed) |

## Limitations

Chinese papers (CNKI/Wanfang/VIP) are not yet supported — no open API or MCP server exists for Chinese academic databases.

## License

MIT
