if [ -z "$MYSQL_DATABASE" ]; then
    echo "MYSQL_DATABASE environment variable not specified"
    exit 1
fi

if [ -z "$MYSQL_USER" ]; then
    echo "MYSQL_USER environment variable not specified"
    exit 1
fi

if [ -z "$MYSQL_PASSWORD" ]; then
    echo "MYSQL_PASSWORD environment variable not specified"
    exit 1
fi

MYSQL_COMMAND="mysql -h mariadb -u $MYSQL_USER --password=$MYSQL_PASSWORD"

until eval $MYSQL_COMMAND -e "use opendc;" ; do
  echo "MariaDB is unavailable - sleeping"
  sleep 1
done

NUM_TABLES=$(eval "$MYSQL_COMMAND -B --disable-column-names -e \"SELECT count(*) FROM information_schema.tables WHERE table_schema='$MYSQL_DATABASE';\"")

# Check if database is empty
if [ "$NUM_TABLES" -eq 0 ]; then
	eval $MYSQL_COMMAND "$MYSQL_DATABASE" < ./database/schema.sql
	eval $MYSQL_COMMAND "$MYSQL_DATABASE" < ./database/test.sql
fi

# Writing databse config values to keys.json
cat keys.json | python -c "import os, sys, json; ks = json.load(sys.stdin); \
    ks['MYSQL_HOST'] = 'mariadb'; \
    ks['MYSQL_PORT'] = '3306'; \
    ks['MYSQL_DATABASE'] = os.environ['MYSQL_DATABASE']; \
    ks['MYSQL_USER'] = os.environ['MYSQL_USER']; \
    ks['MYSQL_PASSWORD'] = os.environ['MYSQL_PASSWORD']; \
    print json.dumps(ks, indent=4)" > new_keys.json
mv new_keys.json keys.json
