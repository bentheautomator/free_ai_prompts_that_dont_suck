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
