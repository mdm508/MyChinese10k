# WordBuilder

A command-line tool for creating fresh, clean SQLite databases for the Chinese Word of the Day app.

## Purpose

The WordBuilder tool creates a clean database file that can be copied into your app bundle. This is useful when:

- The existing database becomes corrupted
- You need a fresh start with all words loaded
- You want to ensure the database is in a clean state

## How to Use

### 1. Run WordBuilder

From the main project directory:

```bash
swift run --package-path Packages/WordBuilder WordBuilder
```

This will:
- Copy the existing database from `MYFrameworks/Persistence/WordModel.sqlite`
- Create a clean copy in your Documents folder
- Verify the file sizes match
- Report success or any issues

### 2. Copy the Database to Your App

After running WordBuilder, copy the clean database to your app bundle:

```bash
# Copy the clean database
cp /Users/m/Documents/WordModel.sqlite MYFrameworks/Persistence/WordModel.sqlite

# Remove any journal files (if they exist)
rm -f MYFrameworks/Persistence/WordModel.sqlite-wal
rm -f MYFrameworks/Persistence/WordModel.sqlite-shm
```

### 3. Build and Run Your App

Your app should now work with the clean database without corruption issues.

## What WordBuilder Does

1. **Locates the source database** - Uses the existing database from `MYFrameworks/Persistence/`
2. **Creates a clean copy** - Copies to your Documents folder for easy access
3. **Verifies integrity** - Checks that file sizes match
4. **Reports status** - Shows success/failure and file locations

## Output Example

```
sup boy
hello boy
✅ Database copied successfully!
📁 Destination: file:///Users/m/Documents/WordModel.sqlite
✅ File sizes match: 44847104 bytes
🎯 Database is ready to be copied to your app!
```

## Troubleshooting

### If WordBuilder Fails

- Make sure the source database exists at `MYFrameworks/Persistence/WordModel.sqlite`
- Check that you have write permissions to your Documents folder
- Ensure the source database isn't corrupted

### If the App Still Shows Corruption

- Make sure you copied the database correctly
- Verify no journal files (.wal, .shm) exist in the app bundle
- Try running WordBuilder again to get a fresh copy

## Requirements

- macOS 13.0 or later
- Swift 6.0
- Access to the source database in `MYFrameworks/Persistence/`

## Notes

- WordBuilder creates a clean copy but doesn't modify the original database
- The tool is designed to be run separately from the main app
- Always verify file sizes match after copying
- Remove journal files to prevent WAL mode issues
