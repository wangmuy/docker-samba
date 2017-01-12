#!/bin/bash
# sample acl

# user list
smbusers="
user1 autoid
user2 autoid
user3 autoid
user4 autoid
"

# share root in container
smbshare_root=/home
# share base in container
smbshare_base=SHARE

# prefix added to every group in container
smbgroup_prefix=home
# $1 group name also used as directory under $smbshare_root/$smbshare_base
# $2... users in group
smbgroups=( \
"admin user1 user2" \
"guest user1 user2 user3 user4" \
)

