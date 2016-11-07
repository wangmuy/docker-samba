#!/bin/bash
#DEBUG=echo
ACL_SH=/data/acl.sh
ACL_DATELOG=./etc/samba/.acl.date


# $1 share name
# $2 path to share
# $3 browsable yes/no
# $4 guestok yes/no
# $5 validusers list of valid users
# $6 readlist list of read list
# $7 writelist list of write list
function addShare() {
local share="$1" path="$2" browsable=${3:-yes} guestok=${4:-yes} \
  validusers=${5:-""} readlist=${6:-""} writelist=${7:-""} \
  file=/etc/samba/smb.conf
sed -i "/\\[$share]\\]/,/^\$/d" $file
echo "[$share]" >> $file
echo "   path = $path" >> $file
echo "   browsable = $browsable" >> $file
echo "   guest ok = $guestok" >> $file
[[ ${validusers:-""} ]] && \
  echo "   valid users = $(tr ',' ' ' <<< $validusers)" >> $file
[[ ${readlist:-""} ]] && \
  echo "   read list = $(tr ',' ' ' <<< $readlist)" >> $file
[[ ${writelist:-""} ]] && \
  echo "   write list = $(tr ',' ' ' <<< $writelist)" >> $file
echo -e "" >> $file
}

# $1 group name
# $2.. users in group
# require: $smbshare_path path to share storage
function syncGroup() {
local g=$1
local group=$smbgroup_prefix$g
grouplist="$grouplist @$group"

$DEBUG groupadd -f $group
$DEBUG mkdir -p $smbshare_path/$g
$DEBUG chmod 3770 $smbshare_path/$g
$DEBUG chown -Rh :$group $smbshare_path/$g

shift
for u in $*; do
  $DEBUG addgroup $u $group
done

addShare $smbshare_base$g $smbshare_path/$g no no "@$group" "@$group" "@$group"
}


# {user id} pairs
function syncUser() {
while [ $# -gt 0 ]; do
  local user=$1
  [ "$2" != "autoid" ] && local id="$2"
  shift; shift
  echo "Adding user $user..."
  $DEBUG useradd -M $user ${id:+-u $id}
  [ $? -eq 0 ] && (echo 123456; echo 123456) | smbpasswd -a $user
done
}

# $smbusers {user id} pairs
# $smbgroups groups with members
function syncAcl() {
. $ACL_SH
smbshare_path=$smbshare_root/$smbshare_base

syncUser $smbusers

for i in ${!smbgroups[@]}; do
  syncGroup ${smbgroups[i]}
done

addShare $smbshare_base $smbshare_path yes no "$grouplist" "$grouplist" "$grouplist"

cp /etc/samba/smb.conf /data/smbconf.bak$(date +%Y%m%d.%H%M)
}


if [ -f $ACL_SH ]; then
  if [ ! -f $ACL_DATELOG -o "$ACL_DATELOG" -ot "$ACL_SH" ]; then
    touch $ACL_DATELOG
    syncAcl
  fi
fi
 
service samba restart
echo done!
tail -f /dev/null
