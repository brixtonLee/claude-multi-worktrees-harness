---
name: file-handling
description: "Magic bytes detection, file type validation, image conversion. Use when handling uploaded files or document processing."
---

# Skill: File Handling

## Magic Bytes Detection — NEVER trust file extensions

```csharp
public FileType Detect(byte[] header) => header switch
{
    [0xFF, 0xD8, 0xFF, ..] => FileType.Jpeg,
    [0x89, 0x50, 0x4E, 0x47, ..] => FileType.Png,
    [0x25, 0x50, 0x44, 0x46, ..] => FileType.Pdf,
    [0x50, 0x4B, ..] when HasXlInternals(header) => FileType.Xlsx,
    [0x50, 0x4B, ..] when HasWordInternals(header) => FileType.Docx,
    [0x47, 0x49, 0x46, ..] => FileType.Gif, // REJECT
    _ => FileType.Unknown
};
```

## Rules

- Never trust file extensions — users rename files
- GIF → always reject (never a legitimate financial document)
- Unknown → reject with user-friendly message
- Supported: JPEG, PNG, PDF, XLSX, DOCX
- PDF → extract text with iText or similar
- Images → send directly to Claude Vision

## Location

```
src/AiAgents.Infrastructure/Files/    ← FileDetector.cs, ImageConverter.cs
src/AiAgents.Domain/Enums/            ← FileType.cs
```
