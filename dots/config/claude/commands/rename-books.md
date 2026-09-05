Clean up messy ebook filenames and file them into `Author/Series` folders with padded series indexes. An optional argument names the directory to organize; with no argument, use the current working directory.

## Phase 1 — identify (read-only)

List the ebook files (`.epub`, `.mobi`, `.azw3`, `.pdf`, `.djvu`) in the target directory. For each one, determine:

1. **Title** — the real work's title, not the scraped filename. Strip scraper cruft: trailing hashes, `Anna's Archive`, publisher, year, mirror names, and `--`-delimited metadata fields. Restore a leading article the scraper dropped (`Silmarillion` → `The Silmarillion`).
2. **Author** — normalized to how the author is commonly credited, not the sort-order form: `Tolkien, J_ R_ R_` → `J.R.R. Tolkien`, `LE GUIN, URSULA K` → `Ursula K. Le Guin`.
3. **Series and position**, if any — the series name and the book's number in it, from your own knowledge of the work. Series order is **publication/writing order**, not internal chronology.
4. **Series length** — total books in the series, used only to decide index padding.

Prefer embedded metadata over the filename when the filename is ambiguous — `unzip -p book.epub '*.opf'` for epub, or `head -c 2000 book.mobi | strings` for mobi — but trust your own knowledge of the work over bad metadata. Scraped years are frequently wrong (e.g. a Silmarillion file tagged 1937, which is actually The Hobbit's year); don't propagate them.

Do not use scraped metadata to invent a series membership that doesn't exist. A standalone book is standalone.

## Phase 2 — plan

Target layout, relative to the target directory:

```
<Author>/
├── <Series>/
│   ├── 1 - <Title>.<ext>
│   └── 2 - <Title>.<ext>
└── <Standalone Title>.<ext>
```

Rules:
- One folder per author, named as the author is commonly credited.
- Books in a series go in a `<Series>` subfolder under the author. Standalone books sit directly in the author folder.
- Series books are prefixed `<index> - `. **Pad the index to the digit width of the total number of books in the series**: a 3-book series gets `1`, `2`, `3` (no padding); a 12-book series gets `01`…`12`; a 100+ book series gets `001`. Padding width comes from the series total, not from how many of its books are present locally.
- Standalone books get no index prefix.
- Never change the file extension, and never re-encode or modify file contents.
- Keep the series name as commonly published (`The Lord of the Rings`, not `LOTR`).

Present the plan as a markdown table — `Current file | New path` — plus a one-line note for any judgment call (bad metadata corrected, series membership decided, unusual padding). Then ask the user to approve with "yes" as the default answer (pre-filled so the user can press tab+enter to accept).

## Phase 3 — apply

On approval, create the directories and `mv` each file into place. Use `mv` — never copy-and-delete, and never overwrite: if a destination path already exists, skip that file and report it rather than clobbering.

Leave non-ebook files where they are. Report the final tree with `ls -R` or an equivalent, and list anything skipped and why.

If the directory contains books whose author, series, or position you genuinely cannot determine, organize everything you are confident about and list the rest as unresolved rather than guessing.
