#include "goose.h"
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <crypt.h>
#include <pthread.h>
#endif

typedef struct { const uint8_t *data; int64_t len; } campfire_bytes;

#ifdef _WIN32
static SRWLOCK writer_mutex = SRWLOCK_INIT;
static CONDITION_VARIABLE writer_ready = CONDITION_VARIABLE_INIT;
#define writer_lock() AcquireSRWLockExclusive(&writer_mutex)
#define writer_unlock() ReleaseSRWLockExclusive(&writer_mutex)
#define writer_wait() SleepConditionVariableSRW(&writer_ready, &writer_mutex, INFINITE, 0)
#define writer_wake() WakeAllConditionVariable(&writer_ready)
#else
static pthread_mutex_t writer_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t writer_ready = PTHREAD_COND_INITIALIZER;
#define writer_lock() pthread_mutex_lock(&writer_mutex)
#define writer_unlock() pthread_mutex_unlock(&writer_mutex)
#define writer_wait() pthread_cond_wait(&writer_ready, &writer_mutex)
#define writer_wake() pthread_cond_broadcast(&writer_ready)
#endif
static uint64_t writer_next, writer_serving;

// FIFO admission avoids SQLite busy-handler retry races between server workers.
void campfire_writer_enter(void) {
    writer_lock();
    uint64_t ticket = writer_next++;
    while (ticket != writer_serving) writer_wait();
    writer_unlock();
}

void campfire_writer_leave(void) {
    writer_lock();
    ++writer_serving;
    writer_wake();
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
