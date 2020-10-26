all:
	nimble -r build

run: 
	nimble run

docker:
	docker build . -t nhxn