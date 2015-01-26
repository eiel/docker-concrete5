# About

https://registry.hub.docker.com/u/eiel/concrete5/

```
$ docker run -d --name my-mysql -e MYSQL_ROOT_PASSWORD="secret" eiel/mysql:concrete5
$ docker run -d --name my-concrete5 --link my-mysql:mysql -p 8002:80 -v `pwd`/concrete5:/var/www/html eiel/concrete5
```

database_host: mysql
database_user: root
database_password: secret
database_name: concrete5

# consultation

https://github.com/docker-library/wordpress
