# Kernel Xiaomi Surya
Since the kernel have different variable on a11-12 and a13-16, i was forced to separate the two version, a11-a12, and a13-a16 into 2 different branches.

### R branches
Its mean a11-a12, use get_monotonic_boottime on their camera.

### T branches
Its mean a13-a16, use ktime_get_ts on their camera.

### LA.UM.9.x
LA.UM.9.x is a staging branches, but now i never touch it, and focus on R and T branches.

### Lineage branches
Up to date branches, I always merge their branches, and add something, as i can try.
