all:
	nimble -r build

run: 
	nimble run

docker:
	docker build . -t nhxn

deploy:
	@git push dokku main:master

git:
	@git remote add dokku dokku@ssh.kbl.io:nhxn