README
======

Steps:
------

1. Login to pi as 'root' user.
2. Copy both attachmets (script and the package) to /root
3. Give executable permissions. Command:
    # chmod 755 configureRTC.sh
4. Execute the script configureRTP.sh with date and time parameters you want to set. This is because, new RTC will need time to be set. So I will use the value specified by user on the system and RTC
  # ./configureRTC.sh <dd> <mm> <yyyy> <HH> <MM> <SS>
where
dd   : DATE
mm   : MONTH
yyyy : YEAR
HH   : HOUR
MM   : MINUTES
SS   : SECONDS

5. After it is successful, please check date and time using command 'date'
6. Power off the Pi, wait for a few minutes. Power on again. Check the time if it has been retained. If it hasn't picked from RTC, you will notice a few minutes lag due to time which you had it powered off. This indicates failure. If time is maintained, it is successful.
7. Anyhow, the system needs a reboot after the configuration, so even if you aren't verifying using step 6, you need to reboot using command 'reboot -f'.