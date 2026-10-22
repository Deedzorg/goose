/* Appended to the pinned SQLite shim by prepare.py. The existing handle table
   validates the connection; the hook records frame counts without doing I/O. */
static _Thread_local int campfire_wal_frames;
static int campfire_note_wal(void *context, sqlite3 *db, const char *name, int pages) {
    (void)context; (void)db; (void)name;
    campfire_wal_frames = pages;
    return SQLITE_OK;
}
int32_t campfire_track_wal(int64_t handle) {
    sqlite3 *db = db_of(handle);
    if (!db) return SQLITE_MISUSE;
    sqlite3_wal_hook(db, campfire_note_wal, NULL);
    return SQLITE_OK;
}
int64_t campfire_wal_pages(void) { return campfire_wal_frames; }
