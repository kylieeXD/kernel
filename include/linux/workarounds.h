/* SPDX-License-Identifier: GPL-2.0 */

#include <linux/jump_label.h>
bool is_legacy_timestamp(void);

/* Fast-path helper for legacy timestamp selection */
extern struct static_key_false legacy_timestamp_key;
static inline bool is_legacy_timestamp_fast(void)
{
	return static_branch_unlikely(&legacy_timestamp_key);
}
