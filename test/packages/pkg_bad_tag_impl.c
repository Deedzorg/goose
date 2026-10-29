/* pkg_bad_tag.goose's C: writes a tag no variant has over the value's
   first bytes, where its tag is. */
#include <string.h>

void bad_tag_scribble(void *s) { memset(s, 0x7f, 4); }
