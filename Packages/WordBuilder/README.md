This Core Data seeding tool performs the following seven functions to prepare your database for production:
1. **Schema Synchronization**: It dynamically loads the managed object model from your shared package to ensure the generated SQLite file exactly matches the version used by your iOS app.
2. **Resource Mapping**: The tool locates the source JSON file within the Swift Package bundle and converts the raw data into a format compatible with Core Data attributes.
3. **Transformer Registration**: It initializes the `StringArrayTransformer` to properly encode Swift arrays, such as meanings and context, into binary data for storage.
4. **Environment Cleanup**: Each run begins by purging previous temporary files and logs to ensure the seeding process starts with a completely clean, uncorrupted state.
5. **High-Performance Ingestion**: It utilizes `NSBatchInsertRequest` to write thousands of records directly to the persistent store, bypassing the overhead of loading individual objects into memory.
6. **WAL Flattening**: The tool forces a checkpoint that merges the Write-Ahead Logging files (`-wal` and `-shm`) into the main `.sqlite` file, creating a single, portable database.
7. **Automated Deployment**: It automatically moves the finalized, optimized SQLite binary to your project's persistence framework folder, making it ready to be bundled with the app.

