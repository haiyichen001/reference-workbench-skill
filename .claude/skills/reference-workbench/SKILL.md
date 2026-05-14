---
name: reference-workbench
description: >
  Academic citation toolkit — verify reference authenticity or write literature reviews
  with auto-generated bibliographies. Checks paper existence, metadata accuracy, and whether
  cited claims are actually supported. Supports PDF, DOCX, TXT, Markdown, LaTeX.
  Use when user asks to: "check citations", "verify references", "audit citations",
  "validate my references", "are these citations real", "write introduction",
  "write literature review", "review my lit review", "generate bibliography",
  "format references", "check my paper's citations", "citation audit",
  "fact-check references", "proofread citations", "verify my bibliography",
  "帮我查引用", "检查论文引用", "写文献综述", "验证参考文献", "引用查证".
  Merges former citation-check and introduction-review skills.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebFetch, WebSearch, AskUserQuestion, Agent, TaskCreate, TaskUpdate, TaskList
compatibility: >
  Search MCPs (paper lookup): arxiv, scholar, paper-search, crossref.
  Tool MCPs (file reading): pdf-reader.
  Python package: rich.
version: 1.3.0
license: MIT
metadata:
  author: haiyichen001
  version: "1.3.0"
  category: academic-writing
  language: bilingual (中文 / English)
  tags:
    - citation-verification
    - citation-check
    - literature-review
    - reference-management
    - reference-validation
    - academic-writing
    - bibliography
    - paper-check
    - citation-audit
    - introduction-writing
    - lit-review
    - academic-publishing
    - research-writing
  supported-formats:
    - PDF
    - DOCX
    - TXT
    - Markdown
    - LaTeX
  sources:
    - agentskills.io specification
    - Semantic Scholar API (via scholar MCP)
    - arXiv API (via arxiv MCP)
    - Google Scholar (via paper-search MCP)
    - PubMed / bioRxiv / medRxiv (via paper-search MCP)
    - Crossref + OpenAlex (via crossref MCP)
  replaces:
    - citation-check-skill (https://github.com/haiyichen001/citation-check-skill)
    - introduction-review-skill (https://github.com/haiyichen001/introduction-review-skill)
  created: "2026-05-14"
  modified: "2026-05-14"
mcp-categories:
  search:
    - arxiv (arXiv API)
    - scholar (Semantic Scholar)
    - paper-search (PubMed / bioRxiv / Google Scholar)
    - crossref (Crossref DOI + OpenAlex + Semantic Scholar)
  tool:
    - pdf-reader (PDF extraction)
  optional:
    - zotero (reference library integration — local API, no key needed)
    - deepl (academic translation / rephrasing — free API key)
---

# Reference Workbench

Two modes. The user chooses at start.

| Mode | Trigger | What it does |
|------|---------|--------------|
| **Check** | Verify citations, audit references | Existence + metadata + content support verification |
| **Write** | Write introduction, literature review | Draft with `[CITE:xxx]` → cite_table.py → table → self-audit |

---

## Phase 0 — MCP Dependency Check (Both Modes)

Scan MCP tools. Output two lines — search first, then tools:

```
Search:  arxiv ✅ | scholar ✅ | paper-search ✅ | crossref ✅
Tool:    pdf-reader ✅
```

If any missing, stop and output install commands. Also run `python ${CLAUDE_SKILL_DIR}/scripts/setup.py` to check Python and `rich`.

---

# Mode A — Citation Check

## Phase A1 — Read + Extract + Ask

### A1.1 Read file

| Format | Method |
|--------|--------|
| PDF | `mcp__pdf-reader__read_pdf` |
| DOCX | `python-docx` via Bash |
| TXT/MD | `Read` |
| LaTeX | `Read` + parse `\cite{}` `\bibitem{}` |

### A1.2 Extract citations

Output raw list:
```
File: paper.pdf (5 pages) | Found N citations | Type: journal/conference/...

[1] journal | Vaswani et al. (2017) "Attention Is All You Need"
    Location: §I, "code-centric automation..."
[2] ...
```

### A1.3 Deduplicate

Normalize by **title + first author** (title: strip punctuation, lowercase; first author: last name). Same paper cited multiple times → merge, keep all locations.

```
Dedup: N raw → M unique papers (N-M duplicates removed)

[1,7]  journal | Vaswani et al. (2017) "Attention Is All You Need"
       Locations: §I "code-centric..." / §III "self-attention enables..."
[2]    conference | ...
[3,5,9] preprint | ...
```

### A1.4 AskUserQuestion

After dedup, call `AskUserQuestion` with two questions:

**Question 1 — Scope (single-select)**
- header: "Scope"
- options:
  - `all` / "Verify all (M unique papers)"
  - `selected` / "Manual selection (e.g. 1,3,5-8)"
- multiSelect: false

**Question 2 — Depth (single-select)**
- header: "Depth"
- options:
  - `quick` / "Quick — Abstract/TLDR only (~10-15k tokens/citation)"
  - `normal` / "Normal — Abstract+Intro+Conclusion (~20-50k tokens/citation) [Recommended]"
  - `deep` / "Deep — Full-text section-by-section (~50-150k tokens/citation) [Token-heavy]"
- multiSelect: false

Wait for user response before Phase A2.

---

## Phase A2 — Parallel Verification (10 per round)

### Rules
- Strictly 10 unique papers per round, overflow auto-continues
- Each paper gets one independent general-purpose sub-agent, **all launched in parallel**
- Agents update status via TaskUpdate
- Round completes → auto-advance to next round

### Single-paper agent task

Each agent receives: original number list (e.g. `[1,7]`), title, authors, year, DOI/ArXiv ID (if available), context around each citation location (±3 sentences).

Three-layer check:

**Layer A — Existence (with fallback chain)**

Try each step in order. Any success → stop. Max 1 retry per step (timeout/network). Failure → next step.

| Priority | Condition | Tool | On failure |
|----------|-----------|------|------------|
| 1 | Has DOI | `mcp__scholar__get_paper` | → Priority 2 |
| 2 | Has ArXiv ID | `mcp__arxiv__get_abstract` | → Priority 3 |
| 3 | Has title | `mcp__scholar__search_papers` (full title) | → Priority 4 |
| 4 | Title search failed | Strip punctuation, quote core phrase, keep 5-8 words, retry `mcp__scholar__search_papers` | → Priority 5 |
| 5 | Title search still failed | `mcp__arxiv__search_papers` | → Priority 6 |
| 6 | Previous two failed | `mcp__paper-search__search_google_scholar` | → Priority 7 |
| 7 | Only author+year+keywords | `mcp__scholar__search_papers` (author + 2-3 core keywords) | → Priority 8 |
| 8 | All above failed | `WebSearch` (paper title + "paper" / "pdf") | → Unverifiable |

Record every fallback path. Final report shows actual data sources used.

**Layer B — Metadata**

Cross-check against `references/citation-fields.md`. Author, title, journal, year, volume/issue/pages are mandatory match fields.

**Layer C — Content support (depth set by user in Phase A1)**

| Depth | Scope |
|-------|-------|
| quick | Abstract + TLDR |
| normal | Abstract + Introduction + Conclusion |
| deep | Full-text section by section |

Extract the claim at each citation location, compare with actual paper content: supports / exaggerates / unrelated / contradicts.

### Progress display

Round start:
```
── Round 1/3 — [1]-[10] — Depth: normal ────────────────────
  ⏳ Launching 10 agents in parallel...
```

Agent completion (real-time):
```
  ✅ [1] Vaswani 2017 — passed
  ⚠️ [4] Yao 2022 — year mismatch
  ⏳ [5] Daareyni 2025 — checking...
```

Round complete:
```
── Round 1/3 done — ✅8 ⚠️1 ❌0 🔍0 📝1 — 11 remaining, entering Round 2...
```

---

## Phase A3 — Summary Report

```
# Citation Verification Report
File: xxx.pdf | Total citations: N
✅ Verified: N | ⚠️ Metadata mismatch: N | ❌ Fabricated: N | 🔍 Unverifiable: N | 📝 Content mismatch: N

[1,7] ✅ Author (Year) "Title"
    Type: journal | Locations: §I Line 42, §III Line 128
    Metadata: all match
    Content: §I claim "xxx" → supported ✓ / §III claim "yyy" → supported ✓
    Evidence: DOI/arXiv link

[2] ⚠️ Author (Year) "Title"
    Type: conference | Location: §2.1 Line 56
    Metadata mismatch: year 2019 → actual 2018
    ...

[3] ❌ Author (Year) "Title"
    Result: paper does not exist, journal does not exist
    ...
```

### Judgment criteria

```
Exists? ─No→ ❌ Fabricated
  └Yes→ Metadata matches?
         ├No→ ⚠️ Metadata mismatch
         └Yes→ Content supports claim?
                ├No→ 📝 Content mismatch
                ├Yes→ ✅ Verified
                └Uncertain→ 🔍 Unverifiable
```

---

# Mode B — Literature Review Writing

Core loop: **normalize → run `cite_table.py` → relay table → self-audit**.

1. **LLM normalizes**: convert ANY citation format (`[REF01]`, `\cite{key}`, `[@key]`, bare `[1]`, etc) to `[CITE:descriptiveKey]`
2. **Script verifies**: `cite_table.py` only reads `[CITE:key]`. Hard-coded, deterministic.
3. **Table proves**: every normalized citation appears in output — nothing missed or invented.

## When NOT to Use

Single-paper summary, pure grammar polishing, non-academic writing, format conversion only.

## Four Scenarios

| User says | Agent does |
|-----------|-----------|
| New review | Draft with `[CITE:xxx]` → script → **table** |
| Add citation | Insert `[CITE:xxx]` → re-run script → **table** |
| Remove citation | Remove `[CITE:xxx]` → re-run script → **table** |
| Audit | Re-run script → checks → **table** |

Every scenario ends: `cite_table.py` → `Read cite_output.txt` → paste table + checks.

## Always-On Checks

After every citation change, re-run `cite_table.py` and walk through:

1. **Stacking** — >3 in one bracket? Warn. >5? Block.
2. **Format** — venue mismatch? Load `references/citation-formats.md` (on-demand) when user specifies a venue. Re-check after ref generation.
3. **Order** — gaps or jumps? Script catches this.
4. **Orphan** — in-text count != reference count? Report.
5. **Tone** — `references/diplomatic-critique.md` (loaded at startup). Never "fails to", "ignores", "fundamentally flawed".
6. **Citation depth** — most citations: **who + did what + found what + [N]**. Opening/transition sentences can be broad. Body paragraphs: each cited paper gets its own sentence.
   - Two valid positions: sentence-end (`...reduced errors by 23% [5].`) or natural pause (`...as shown in prior work [5,6], the trend...`).
   - NEVER: `, [5],` (comma sandwich) or `Smith [5] proposed` (author-attached). Script flags these as ⚠️.

Report: one line per check, `✅` or `⚠️`. Then full re-scan (never fix one and skip the rest). Then read all `[N]` aloud to catch awkward flow.

## Table Protocol (Mandatory)

Auto-detect `.bib` file in project dir. If found, use `--bib` mode.

```
python ${CLAUDE_SKILL_DIR}/scripts/cite_table.py <draft> [--bib <bib_file>]
Read: ${CLAUDE_SKILL_DIR}/scripts/cite_output.txt
→ Paste table + audit. Then: "Need to add, remove, or change any citations?"
```

Without `--bib`: 5 columns (# | Author | Body Context | Reference | Status). With `--bib`: 6 columns comparing body order, bib key, bib position, and reference list order. Bilingual (中文/English auto-detected). Repeated citations get `↳` sub-rows.

## Reference Files

- `anti-laziness-protocol.md` — **loaded at startup**. Mandatory 5-step verification gate. Itemized only, no batching.
- `citation-placement-rules.md` — **loaded at startup**. Per-citation placement enforcement.
- `diplomatic-critique.md` — **loaded at startup**. Mandatory tone guard.
- `citation-formats.md` — **loaded on-demand** when user specifies a venue. IEEE/SCI/EI/GB7714/APA/MLA/Chicago/ACM rules.
- `citation-fields.md` — **loaded on-demand** for metadata cross-checking by citation type.

## Script

- `cite_table.py` — single core engine. Scan, number, table, position check, bilingual, `--bib` mode.

---

## Optional MCPs (Not Required)

These enhance the skill but are not mandatory. If missing, the skill runs normally.

| MCP | What it adds | Install |
|-----|-------------|---------|
| **Zotero** | Search your Zotero library, import papers, read PDF annotations, write Word docs with live citations | `npx smithery install @alisoroushmd/zotero-mcp` |
| **DeepL** | Academic translation (中文 ↔ English), glossary-locked terminology, rephrase for clarity | `npm install deepl-mcp-server` (needs free API key) |

If installed, the agent can use them automatically during write sessions for reference management and translation tasks.
