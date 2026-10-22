namespace campfire;
import std;
import sqlite;

struct CheckpointJob { stop: bool = false }
extern fn campfire_track_wal(handle: i64) -> i32;
extern fn campfire_wal_pages() -> i64;
extern fn campfire_checkpoint_lock();
extern fn campfire_checkpoint_unlock();
extern fn campfire_checkpoint_due(pages: i64) -> bool;

fn checkpoint(db: sqlite::Db, mode: const u8[:]) {
    var q=sqlite::Stmt {};
    campfire_checkpoint_lock();
    let failed=sqlite::run() {
        q=sqlite::prepare(db,str("PRAGMA wal_checkpoint(",mode,")"));
        if sqlite::step(q) && sqlite::column_i64(q,0)!=0 { write_stderr("WAL checkpoint remains busy\n"); }
    };
    sqlite::finalize(q); campfire_checkpoint_unlock();
    for e in failed { write_stderr(str("WAL checkpoint error: ",e.message,"\n")); }
}

thread_fn checkpointer(path: u8[]) {
    var db=sqlite::Db {};
    let failed=sqlite::run() {
        db=sqlite::open(path,sqlite::READ_WRITE); sqlite::busy_timeout(db,5000);
        sqlite::exec(db,"PRAGMA synchronous=NORMAL;");
    };
    if failed.len>0 { for e in failed { write_stderr(str("Cannot start checkpointer: ",e.message,"\n")); } exit(1); }
    loop {
        let job=qget<CheckpointJob>(); checkpoint(db,if job.stop {"TRUNCATE"} else {"PASSIVE"});
        if job.stop { break; }
    }
    sqlite::close(db);
}

fn checkpoint_after_write(db: sqlite::Db) {
    let pages=campfire_wal_pages();
    if pages>=10000 { checkpoint(db,"RESTART"); }
    else if campfire_checkpoint_due(pages) { qput(CheckpointJob { .. }); }
}
