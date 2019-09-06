#!/bin/sh
echo '****************************************************************************'
echo '              import_mysql_db.sh                                            '
echo '                      by niuren.zhu                                         '
echo '                           2019.09.06                                       '
echo '  说明：                                                                    '
echo '    1. 解压工作目录sql.gz包。                                               '
echo '    2. 检查sql文件表名及用户。                                              '
echo '    3. 导入sql文件到数据库。                                                '
echo '    4. 参数1，工作目录。                                                    '
echo '****************************************************************************'
# 工作目录
WORK_FOLDER=`pwd`

echo --工作目录：${WORK_FOLDER}

# 解压文件
for FILE in `find ${WORK_FOLDER} -maxdepth 1 -type f -name '*.sql.gz'`
do
  echo --解压:${FILE}
  gunzip "${FILE}"
done

# 检查文件
if [ ! -e "${WORK_FOLDER}/fixed" ]; then
  mkdir "${WORK_FOLDER}/fixed"
fi;
for FILE in `find ${WORK_FOLDER} -maxdepth 1 -type f -name '*.sql'`
do
  echo --检查:${FILE}
  DB_NAME=${FILE##*/}
  DB_NAME=${DB_NAME%.*}
  echo "-- Create and using Database" >${FILE%/*}/fixed/${FILE##*/}
  echo "CREATE SCHEMA \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4;" >>${FILE%/*}/fixed/${FILE##*/}
  echo "USE \`${DB_NAME}\`;" >>${FILE%/*}/fixed/${FILE##*/}
  echo "" >>${FILE%/*}/fixed/${FILE##*/}
  sed -e 's/`ava.*`/\U&/g;s/AVAUSER/root/g' ${FILE} >>${FILE%/*}/fixed/${FILE##*/}
done

# 执行文件
if [ -e "${WORK_FOLDER}/fixed" ]; then
  echo --输入数据库连接信息（默认值回车）：
  echo -n "Server(ibas-db-mysql):"
  read SERVER
  if [ "${SERVER}" = "" ];then SERVER=ibas-db-mysql; fi;
  echo -n "User(root):"
  read USER
  if [ "${USER}" = "" ];then USER=root; fi;
  echo -n "Password(1q2w3e):"
  read PASSWORD
  if [ "${PASSWORD}" = "" ];then PASSWORD=1q2w3e; fi;

  for FILE in `find "${WORK_FOLDER}/fixed" -maxdepth 1 -type f -name '*.sql'`
  do
    echo --执行:${FILE}
    mysql -h${SERVER} -u${USER} -p${PASSWORD} <${FILE}
  done
fi;

echo --操作完成
