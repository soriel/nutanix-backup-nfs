#!/bin/bash
date=$(date  +%Y-%m-%d)
ipnutanix=$'192.168.26.7'
mailto=$'team@integrasky.ru'
namenutanix=$'Nutanx stek'
for vm in 'mikrotik.st.local' 
do
echo "Start backup" >> /var/log/nutanix-backup-"$vm"-"$date".log
date >> /var/log/nutanix-backup-"$vm"-"$date".log
ssh nutanix@"$ipnutanix" "env vm=$vm /usr/local/nutanix/bin/acli vm.clone "$vm"-backup clone_from_vm="$vm""
sleep 30s
diskuid1="$(ssh nutanix@"$ipnutanix" "env vm=$vm /usr/local/nutanix/bin/acli vm.disk_get "$vm"-backup" | grep "vmdisk_uuid" | grep -v source_vmdisk_uuid | sed 's/.$//' | sed -r 's/^[^"]+//' | sed -r 's/.{,1}//')";
while read -r diskuid; 
do
echo "$diskuid";
cd /mnt/11tb/nutanix/;
cp /mnt/pve/nut_nfs/.acropolis/vmdisk/"$diskuid" /mnt/11tb/nutanix/"$vm"-"$diskuid"-"$date"
echo "VM disk file name" >> /var/log/nutanix-backup-"$vm"-"$date".log
du -hs "$vm"-"$diskuid"-"$date" >> /var/log/nutanix-backup-"$vm"-"$date".log
done <<<"$diskuid1"
find /mnt/11tb/nutanix/ -name ""$vm"-*" -mtime +2 -exec rm -f {} \;
find /mnt/11tb/nutanix/ -name ""$vm"-*.log" -mtime +5 -exec rm -f {} \;
yes yes | ssh nutanix@"$ipnutanix" "env vm=$vm /usr/local/nutanix/bin/acli vm.delete "$vm"-backup"
echo "Backup done" >> /var/log/nutanix-backup-"$vm"-"$date".log
date >> /var/log/nutanix-backup-"$vm"-"$date".log
mail -s "Backup $namenutanix $ipnutanix $vm $date" "$mailto" < /var/log/nutanix-backup-"$vm"-"$date".log
done
