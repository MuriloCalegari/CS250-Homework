all: mersenne recurse covidtracker

clean:
	rm -f mersenne recurse covidtracker

squares: mersenne.c
	g++ -g -o $@ $<

recurse: recurse.c
	g++ -g -o $@ $<

covidtracker: covidtracker.c
	g++ -g -o $@ $<
