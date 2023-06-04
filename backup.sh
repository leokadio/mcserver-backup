#!/bin/bash
: '
inspirado por mc-backup by J-Bentley, mas com menos coisas :D
https://github.com/J-Bentley/mc-backup.sh'
 
serverDir="/home/leokadio/s_mc/live"
backupDir="/home/leokadio/s_mc/backup"
startScript="bash boot.sh"
gracePeriod="1m"
serverWorlds=("world" "world_nether" "world_the_end")
# Don't change anything past this line unless you know what you're doing.
 
currentDay=$(date +"%Y-%m-%d")
currentTime=$(date +"%H:%M")
screens=$(ls /var/run/screen/S-$USER -1 | wc -l || 0) # a file is created in /var/run/screen/S-$user for every screen session
serverRunning=true
 
log () {
    # Echos text passed to function and appends to file at same time
    builtin echo -e "$@" | tee -a log.txt
}
stopHandling () {
    # injects commands into screen via stuff to notify players, sleeps for graceperiod, stop server and sleeps for hdd spin times
    log "[$currentDay] [$currentTime] Avisando que servidor vai fechar\n"
    screen -p 0 -X stuff "say Server reiniciando em $gracePeriod!$(printf \\r)"
    sleep $gracePeriod
    screen -p 0 -X stuff "say Server reiniciando!$(printf \\r)"
    screen -p 0 -X stuff "save-all$(printf \\r)"
    sleep 5
    screen -p 0 -X stuff "stop$(printf \\r)"
    sleep 5
}
 
# Logs error and cancels script if serverDir isn't found
if [ ! -d $serverDir ]; then
    log "[$currentDay] [$currentTime] Error: Server folder not found! Backup has been cancelled. ($serverDir doesnt exist)\n"
    exit 1
fi
# Logs error and cancels script if backupDir isn't found
if [ ! -d $backupDir ]; then
    log "[$currentDay] [$currentTime] Error: Backup folder not found! Backup has been cancelled. ($backupDir doesnt exist)\n"
    exit 1
fi
# Logs error if java process isn't running but will continue anyways
if ! ps -e | grep -q "java"; then
    log "[$currentDay] [$currentTime] Servidor nao esta rodando, logo nao sera fechado. Backup sera feito igual\n"
    serverRunning=false
fi
 # Logs error if no screen sessions or more than one are running
if [ $screens -eq 0 ]; then
    log "[$currentDay] [$currentTime] Error: No screen sessions running! Backup has been cancelled.\n"
    exit 1
elif [ $screens -gt 1 ]; then
    log "\n[$currentDay] [$currentTime] Error: More than 1 screen session is running! Backup has been cancelled.\n"
    exit 1
fi
# Wont execute stopHandling if server is offline upon script start
if $serverRunning; then
    stopHandling
fi
 
log "[$currentDay] [$currentTime] Backup iniciado\n"
zip -r full_backup.zip $serverDir

rm /home/leokadio/s_mc/backup/full_backup.zip
mv /home/leokadio/s_mc/scripts/serverbackup-$currentDay.zip /home/leokadio/s_mc/backup  
log "[$currentDay] [$currentTime] Backup feito.\n"

 
# Will restart server if it was online upon script start; wont restart server if it was already offline upon script launch
if $serverRunning; then
    screen -p 0 -X stuff "$startScript $(printf \\r)"
    log "[$currentDay] [$currentTime] Servidor religado.\n"
fi
exit 0