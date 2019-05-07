package mysql

operator mysql: {
	image:   "mysql:5.3.2.1"
	version: "5.3.2.1"
	expose port tcp:       3306
	volume data mountPath: "/var/lib/mysql"

    kubernetes spec template spec: {
        containers: [{
            securityContext privileged: true
        }]
    }

    task "init": _taskBase & {
        command: [
            "/bin/sh",
            "-c",
            "mysql -u root -h {{NAME}}-mysql -p{{PASSWORD}} -e \"CREATE TABLE example ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );\" kudo"
        ]
    }

    task "backup": _taskBase & {
        command: [
            "/bin/sh",
            "-c",
            "backup /var/data"
        ]
    }

    task "restore": _taskBase & {
        command: [
            "/bin/sh",
            "-c",
            "restore"
        ]
    }

    task "mysql": {
        image: "foo"
    }

    plan deploy phase mysql strategy: "serial"
    plan deploy phase mysql tasks: ["mysql", "init"]
    plan deploy phase secondphase tasks: ["backup"]
}

_taskBase: {
    kind: "Job"
    image: "mysql:5.7"
    volume backup mountPath "/var/data"
}