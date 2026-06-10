---
title: Disable External Entities When Parsing XML
slug: disable-xml-external-entities
category: security
tags: [universal, security, injection]
works_with: all
severity: critical
one_liner: "AI parsing untrusted XML with external entity resolution enabled"
---

# Disable External Entities When Parsing XML

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents XXE: XML parsers configured to fetch URLs and read local files on an attacker's instruction.

**[Copy-paste ready version](../../install/disable-xml-external-entities.md)** — just the instruction block, no explanation.

## The Problem

XML has a feature most people learn about from the vulnerability it causes: a document can declare an "external entity" pointing at a file path or URL, and a compliant parser will fetch it and splice the contents into the document. Feed such a parser an uploaded invoice, a SOAP request, an SVG, or an RSS feed containing `<!ENTITY xxe SYSTEM "file:///etc/passwd">`, and the parse result hands the attacker your files. Point the entity at `http://169.254.169.254/` instead and XXE becomes SSRF into your cloud metadata. Billion-laughs entity expansion gets you denial of service as a bonus.

Whether an AI-generated parser is vulnerable depends entirely on which library and version the model happens to reach for, because defaults vary wildly: Java's `DocumentBuilderFactory`, `SAXParser`, and `XMLReader` resolve entities unless explicitly configured not to (the fix is several non-obvious feature flags), PHP's older libxml behavior needed explicit disabling, .NET changed defaults across framework versions, and Python's lxml has `resolve_entities=True` in its default parser. The AI doesn't reason about this; it emits the most common parsing snippet for the language, which in Java is the vulnerable one. Worse, when entity-related parse errors occur, the "fix" in circulation is to turn entity processing *on*.

XML arrives in more places than people notice: file uploads (DOCX and XLSX are zipped XML, SVG is XML), SAML assertions, RSS/Atom ingestion, SOAP integrations, sitemap fetchers.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Disable External Entities When Parsing XML

ALWAYS configure XML parsers handling untrusted input to forbid DTDs and external entities. In ecosystems where the parser is unsafe by default, the hardening flags are mandatory boilerplate, not optional.

An entity-resolving parser is a file-reader and URL-fetcher that takes instructions from the document it's parsing.

- Java: on `DocumentBuilderFactory`/`SAXParserFactory`, set `factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` (the strongest single switch), plus disable `external-general-entities`/`external-parameter-entities`, and `setXIncludeAware(false)`, `setExpandEntityReferences(false)`. Same treatment for `XMLInputFactory` (`SUPPORT_DTD: false`) and transformers (`ACCESS_EXTERNAL_DTD`/`ACCESS_EXTERNAL_STYLESHEET` to "").
- Python: prefer `defusedxml` for untrusted XML; with lxml, use `etree.XMLParser(resolve_entities=False, no_network=True)` and avoid DTD validation of untrusted docs.
- PHP: ensure libxml >= 2.9 or call `libxml_disable_entity_loader(true)` on older versions; don't pass `LIBXML_NOENT` (it *enables* substitution, despite the name).
- .NET: `XmlReaderSettings { DtdProcessing = DtdProcessing.Prohibit }`; do not assign an `XmlResolver` to re-enable fetching.
- Treat as untrusted XML: uploaded files including SVG and Office formats (zipped XML), SAML responses, SOAP bodies, RSS/Atom feeds, sitemaps, and any third-party API response in XML.
- If a parse error mentions undefined entities or DOCTYPE, the fix is rejecting the document or stripping the DTD, never enabling entity resolution to make the document parse.
- Where the data doesn't have to be XML at all, prefer JSON and delete the problem.

**Red flags that you're about to violate this:**
- "The default parser configuration is presumably safe in a modern library..."
- "LIBXML_NOENT sounds like it disables entities, I'll add it..."
- "This XML comes from a partner's system, not from attackers..."
- "The parse fails on the DOCTYPE, so I'll enable DTD processing..."
- "It's just an SVG thumbnail pipeline, not an XML API..."
- "Adding five feature flags for one parse call is overkill..."

---

## Why It Works

1. **It overrides the trust-the-default heuristic.** The AI assumes library defaults are safe because they usually are; XML is the ecosystem where that heuristic fails, and saying so per-platform is the only thing that changes the emitted snippet.

2. **It gives the exact flag incantations.** The Java hardening is genuinely obscure — six settings with URL-shaped names — and no model retrieves them reliably without the text in context.

3. **It defuses the trap fixes.** `LIBXML_NOENT` and "enable DTD to fix the parse error" are the two places where the AI makes things worse while visibly trying to help; both are named with the correct alternative.

4. **It expands what counts as XML input.** SVG uploads and SAML assertions don't pattern-match as "parsing XML" in the model's planning; the list triggers the rule in the disguised cases where XXE actually gets found.

## Origin

An expense tool accepted XLSX uploads and parsed the embedded XML with a default-configured Java factory. A crafted spreadsheet carrying an external entity read the application server's environment file and exfiltrated it via a parameter-entity callback URL, all during what looked like a normal upload. The patch was six `setFeature` lines that the OWASP cheat sheet had listed verbatim for a decade; the incident write-up just linked to it.
