# Lessons

- `crusoe` is not available in this environment; initialize `.ai/` memory files manually when missing.
- Flutter commands may need escalated execution because SDK/cache access can hang inside the sandbox.
- Import recognition should normalize headers by removing BOM, parenthetical notes, whitespace, and punctuation; otherwise real spreadsheets such as `岗位名称（必填）` may fail to map.
- For XLSX imports with the `excel` package, read `TextCellValue.value.text` and date values explicitly instead of relying only on `toString()`.
