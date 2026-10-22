#include "goose.h"
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <crypt.h>
#include <pthread.h>
#endif

typedef struct { const uint8_t *data; int64_t len; } campfire_bytes;
typedef struct { const uint64_t *data; int64_t len; } campfire_times;

static int profile_writes;
void campfire_profile_enable(uint8_t enabled) { profile_writes = enabled; }
uint64_t campfire_profile_clock(void) {
    if (!profile_writes) return 0;
    struct timespec now;
#ifdef _WIN32
    timespec_get(&now, TIME_UTC);
#else
    clock_gettime(CLOCK_MONOTONIC, &now);
#endif
    return (uint64_t)now.tv_sec * 1000000000 + now.tv_nsec;
}

void campfire_profile_record(campfire_times times) {
    if (!profile_writes || times.len != 6) return;
    static _Thread_local uint64_t count, totals[6];
    for (int i = 0; i < 6; ++i) totals[i] += times.data[i];
    if (++count == 1024) {
        fprintf(stderr, "write_profile count=%llu context_ns=%llu wait_ns=%llu sql_ns=%llu render_ns=%llu commit_ns=%llu cleanup_ns=%llu\n",
                (unsigned long long)count, (unsigned long long)totals[0], (unsigned long long)totals[1],
                (unsigned long long)totals[2], (unsigned long long)totals[3], (unsigned long long)totals[4], (unsigned long long)totals[5]);
        count = 0;
        memset(totals, 0, sizeof totals);
    }
}

int64_t campfire_epoch_ms(campfire_bytes text) {
    if (text.len < 19 || text.len >= 64) return 0;
    char input[64]; memcpy(input, text.data, (size_t)text.len); input[text.len] = 0;
    if (input[10] == 'T') input[10] = ' ';
    struct tm utc = {0};
    if (sscanf(input, "%d-%d-%d %d:%d:%d", &utc.tm_year, &utc.tm_mon, &utc.tm_mday,
               &utc.tm_hour, &utc.tm_min, &utc.tm_sec) != 6) return 0;
    utc.tm_year -= 1900; --utc.tm_mon;
#ifdef _WIN32
    time_t seconds = _mkgmtime(&utc);
#else
    time_t seconds = timegm(&utc);
#endif
    // Rails converts the exact decimal timestamp to double before multiplying by 1000.
    char decimal[96];
    snprintf(decimal, sizeof decimal, "%lld%s", (long long)seconds, input[19] == '.' ? input + 19 : "");
    return (int64_t)(strtod(decimal, NULL) * 1000.0);
}

#ifdef _WIN32
static SRWLOCK writer_mutex = SRWLOCK_INIT, checkpoint_mutex = SRWLOCK_INIT;
typedef CONDITION_VARIABLE writer_condition;
#define writer_lock() AcquireSRWLockExclusive(&writer_mutex)
#define writer_unlock() ReleaseSRWLockExclusive(&writer_mutex)
#define condition_init(c) InitializeConditionVariable(c)
#define condition_wait(c) SleepConditionVariableSRW(c, &writer_mutex, INFINITE, 0)
#define condition_signal(c) WakeConditionVariable(c)
#define condition_destroy(c) ((void)(c))
void campfire_checkpoint_lock(void) { AcquireSRWLockExclusive(&checkpoint_mutex); }
void campfire_checkpoint_unlock(void) { ReleaseSRWLockExclusive(&checkpoint_mutex); }
#else
static pthread_mutex_t writer_mutex = PTHREAD_MUTEX_INITIALIZER, checkpoint_mutex = PTHREAD_MUTEX_INITIALIZER;
typedef pthread_cond_t writer_condition;
#define writer_lock() pthread_mutex_lock(&writer_mutex)
#define writer_unlock() pthread_mutex_unlock(&writer_mutex)
#define condition_init(c) pthread_cond_init(c, NULL)
#define condition_wait(c) pthread_cond_wait(c, &writer_mutex)
#define condition_signal(c) pthread_cond_signal(c)
#define condition_destroy(c) pthread_cond_destroy(c)
void campfire_checkpoint_lock(void) { pthread_mutex_lock(&checkpoint_mutex); }
void campfire_checkpoint_unlock(void) { pthread_mutex_unlock(&checkpoint_mutex); }
#endif

typedef struct writer_waiter {
    struct writer_waiter *next;
    writer_condition condition;
    int ready;
} writer_waiter;
static writer_waiter *writer_first, *writer_last;
static int writer_active;
static int64_t checkpoint_woken_at;

// Called under writer admission, so the shared notification counter needs no lock.
uint8_t campfire_checkpoint_due(int64_t pages) {
    if (pages < checkpoint_woken_at) checkpoint_woken_at = 0;
    if (pages - checkpoint_woken_at < 1000) return 0;
    checkpoint_woken_at = pages;
    return 1;
}

// FIFO admission wakes only the next writer. Each queued node belongs to the
// waiting call's stack and is removed before that call can return.
void campfire_writer_enter(void) {
    writer_lock();
    if (!writer_active) { writer_active = 1; writer_unlock(); return; }
    writer_waiter waiter = {0};
    condition_init(&waiter.condition);
    if (writer_last) writer_last->next = &waiter; else writer_first = &waiter;
    writer_last = &waiter;
    while (!waiter.ready) condition_wait(&waiter.condition);
    writer_unlock();
    condition_destroy(&waiter.condition);
}

void campfire_writer_leave(void) {
    writer_lock();
    if (writer_first) {
        writer_waiter *next = writer_first;
        writer_first = next->next;
        if (!writer_first) writer_last = NULL;
        next->ready = 1;
        condition_signal(&next->condition);
    } else { writer_active = 0; }
    writer_unlock();
}

static void campfire_timestamp(gs_rref out, int sql, int future, int seconds_ago) {
    struct timespec instant;
    if (!timespec_get(&instant, TIME_UTC)) return;
    time_t now = instant.tv_sec - seconds_ago;
    struct tm utc;
#ifdef _WIN32
    if (gmtime_s(&utc, &now)) return;
#else
    if (!gmtime_r(&now, &utc)) return;
#endif
    if (future) {
        utc.tm_year += 20;
        int year = utc.tm_year + 1900;
        if (utc.tm_mon == 1 && utc.tm_mday == 29 && (year % 4 || (year % 100 == 0 && year % 400)))
            utc.tm_mday = 28;
    }
    char text[40];
    size_t length = strftime(text, sizeof text, sql ? "%Y-%m-%d %H:%M:%S" : "%Y-%m-%dT%H:%M:%S", &utc);
    int suffix = sql ? snprintf(text + length, sizeof text - length, ".%06ld", instant.tv_nsec / 1000)
                     : snprintf(text + length, sizeof text - length, ".%03ldZ", instant.tv_nsec / 1000000);
    if (suffix < 0 || (size_t)suffix >= sizeof text - length) return;
    length += (size_t)suffix;
    gs_bld_append(out, text, (int64_t)length);
}

void campfire_now(gs_rref out) { campfire_timestamp(out, 0, 0, 0); }
void campfire_sql_now(gs_rref out) { campfire_timestamp(out, 1, 0, 0); }
void campfire_expiry(gs_rref out) { campfire_timestamp(out, 0, 1, 0); }
void campfire_disconnected_before(gs_rref out) { campfire_timestamp(out, 1, 0, 60); }

int32_t campfire_password_verify(campfire_bytes password, campfire_bytes digest) {
#ifdef _WIN32
    (void)password;
    (void)digest;
    return -1;
#else
    if (password.len < 0 || password.len > 4096 || digest.len != 60 ||
        memchr(password.data, 0, (size_t)password.len) || digest.data[0] != '$' || digest.data[1] != '2')
        return 0;
    char input[73], setting[61];
    size_t length = password.len > 72 ? 72 : (size_t)password.len;
    memcpy(input, password.data, length);
    input[length] = 0;
    memcpy(setting, digest.data, 60);
    setting[60] = 0;
    struct crypt_data state = {0};
    char *result = crypt_r(input, setting, &state);
    if (!result || strlen(result) != 60) return 0;
    unsigned difference = 0;
    for (int i = 0; i < 60; ++i) difference |= (unsigned char)result[i] ^ digest.data[i];
    return difference == 0;
#endif
}
