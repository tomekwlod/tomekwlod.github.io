deploy:
	@echo ""
	@echo "WARNING: remember to bump .env version if you want to change cronjob"
	@echo ""
	@echo /bin/bash cron.yaml.sh
	@echo /bin/bash cron.yaml.sh .env.kub.prod backupmysql.sh
	@echo ""

pod:
	@echo "Script to just run logic once for testing purposes"
	@echo ""
	@echo "WARNING: remember to bump .env version if you want to change cronjob"
	@echo ""
	@echo /bin/bash job.yaml.sh
	@echo /bin/bash job.yaml.sh .env.kub.prod backupmysql.sh
	@echo ""

run:
	docker run -it -v "$(pwd)/gitpull:/home/node/app" ubuntu:18.04 bash
