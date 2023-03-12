deploy=/deploy
path=$(pwd)
project=$(basename "$path")
include="--include 'start.sh' --include 'stop.sh' --include 'update.sh' --include 'config.json' --include '$project'"
if [ -e certs ]
then
  include="$include --include 'certs' --include 'certs/*'"
fi
exclude="--exclude '*/*'"

# build
: > build.sh
chmod u+x build.sh
echo "git pull && go build . && rsync -avzP $include $exclude ../$project $DEPLOY_HOST:/deploy" >> build.sh

# start
: > start.sh
chmod u+x start.sh
{
  echo "if [ ! -e logs ]"
  echo "then"
  echo "  mkdir logs"
  echo "fi"
  echo "nohup ./$project >> ./logs/log.txt 2>&1 &"
} >> start.sh

# stop
: > stop.sh
chmod u+x stop.sh
{
  echo "id=\$(pgrep -x $project)"
  echo "if [ \"\${id}\" != \"\" ]"
  echo "then"
  echo "  kill -SIGTERM \"\${id}\""
  echo "fi"
} >> stop.sh

# update
: > update.sh
chmod u+x update.sh
echo "rsync -avzP deploy@$DEPLOY_HOST:/deploy/$project/$project ." >> update.sh

# alias
: > rc.txt
{
  echo "export LS_OPTIONS='--color=auto'"
  echo "eval \"\$(dircolors)\""
  echo "alias ls='ls \$LS_OPTIONS'"
  echo "alias ll='ls \$LS_OPTIONS -l'"
  echo "alias l='ls \$LS_OPTIONS -lA'"
  echo

  echo "alias .d='cd $deploy'"
  echo "alias .m='mongosh -u root -p 123456 --authenticationDatabase admin 127.0.0.1:27017/$project'"
  echo

  echo "alias .r${project:0:1}='cd $deploy/$project && ./stop.sh && sleep 1 && ./start.sh && cd - > /dev/null'"
  echo "alias .u${project:0:1}='cd $deploy/$project && ./update.sh && ./stop.sh && sleep 1 && ./start.sh && cd - > /dev/null'"
  echo "alias .p${project:0:1}='pgrep -x $project'"
  echo "alias .t${project:0:1}='tail -f $deploy/$project/zlog.txt'"
  echo

  echo "rsync -avzP deploy@$DEPLOY_HOST:/deploy/$project ."
} >> rc.txt

# build
echo '--> go get && go mod tidy && ./build.sh'
go get && go mod tidy && ./build.sh
