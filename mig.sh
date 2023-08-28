#!/bin/sh
. /etc/hostevac/admin-openrc.sh
while true; do

        # Fetch the list of hosts using the OpenStack CLI
        hosts=$(openstack compute service list --service nova-compute -f value -c Host | xargs -I {} openstack compute service list --host {} | grep 'down' | awk '{print $6}')

        for host in $hosts; do

                # MySQL connection parameters
                DB_HOST="cluster1"
                DB_USER="hostevac"
                DB_PASS="hostevac"
                DB_NAME="hostevac"
                TABLE_NAME="evacuation"

                # Value to check
                VALUE_TO_CHECK="migrating"
                NEW_VALUE="migrating"
                HOSTN=$(hostname -s)

                # Check if the value exists in the table
                if [[ $(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -N -B -e "SELECT COUNT(*) FROM $DB_NAME.$TABLE_NAME WHERE reason = '$VALUE_TO_CHECK';") -gt 0 ]]; then
                    echo "Instance already in evacuation from another host."
                else
                    echo "This host will take over the evacuation."
                        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "INSERT INTO $DB_NAME.$TABLE_NAME (hostname, reason) VALUES ('$HOSTN', '$NEW_VALUE');"
                        sleep 1s

                        if [[ $(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -N -B -e "SELECT COUNT(*) FROM $DB_NAME.$TABLE_NAME WHERE reason = '$VALUE_TO_CHECK' AND hostname = '$HOSTN';") -gt 0 ]]; then
                                echo "This host has the lead!"

                                # Get all the instances on that host
                                instances=$(openstack server list --all-projects --host $host --status ACTIVE -f value -c ID)

                                # Get Hypervisor Zone
                                hypzone=$(openstack compute service list --host $host -f value -c Zone)

                                # Get available Hypervisors in the same Zone
                                hypinzone=$(openstack compute service list --service nova-compute -f value -c Host | xargs -I {} openstack compute service list --host {} | grep $hypzone | grep 'up' | grep 'enabled' | awk '{print $6}' | head -n 1)

                                # Evacuate all instances that are active
                                for inst in $instances; do
                                        if [ -z "$hypinzone" ]; then
                                                current_datetime=$(date +"%Y-%m-%d %H:%M:%S")
                                                echo "$current_datetime evacuation for $inst"
                                                echo "Failover to another zone $hypinzone"
                                                openstack server evacuate $inst --shared-storage
                                                sleep 2s
                                        else
                                                current_datetime=$(date +"%Y-%m-%d %H:%M:%S")
                                                echo "$current_datetime evacuation for $inst"
                                                echo "Failover to hypervisor $hypinzone"
                                                openstack server evacuate $inst --host $hypinzone --os-compute-api-version 2.29
                                        fi
                                done
                                sleep 5s
                                # Empty the DB
                                mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "DELETE FROM $DB_NAME.$TABLE_NAME;"

                        else
                                echo "It's another host that has the lead!"

                        fi
                fi
        done

        sleep 5s
done