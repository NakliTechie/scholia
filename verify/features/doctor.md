# doctor

- **What exists:** an offline hygiene worklist: dangling wikilinks, unresolved `#^anchors`, near-duplicate and singleton tags, orphan sources, realm tags, isolated notes, unreferenced assets, thin metadata, inbox status. Exits 0 on any valid vault, whatever it finds.
- **How a user reaches it:** `scholia doctor [--limit N --min-inbound N]`.
- **Drive it:** `verify/verify verify doctor`.
- **What usually lies:** a dangling target linked once is counted but not listed (only 2+ are). A note with unclosed frontmatter or binary content is indexed as body text and only shows as thin metadata.
