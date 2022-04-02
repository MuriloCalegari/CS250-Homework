#include<stdio.h>
#include<stdlib.h>
#include<cstring>

#define DEBUG 1

// FLAGS - STORE ALGORITHM
// Useful for bit-masking
#define WRITE_BACK 1 << 0
#define WRITE_THROUGH 1 << 1
#define WRITE_ALLOCATE 1 << 2
#define WRITE_NON_ALLOCATE 1 << 3

// COMMANDS
#define COMMAND_LOAD = 0
#define COMMAND_STORE = 1

// Cache parameters
int storeAlg; // Either (WRITE_BACK and WRITE_ALLOCATE) or (WRITE_THROUGH and WRITE_NO_ALLOCATE)
int cacheSize; // in KB, not including tags or valid bits
int nWays; // associativity
int blockSize; // in bytes
int nSets;

// Reading parameters
FILE* file;
#define COMMAND_MAX_STRING_SIZE 10
#define ADDRESS_MAX_STRING_SIZE 5
#define SIZE_MAX_STRING_SIZE 3
#define DATA_MAX_SIZE 129
#define LINE_MAX_STRING_SIZE 142

// Way structure
typedef struct way way;
struct way {
	int valid;
	int tag;
	int data;
	int LRUT; // used for LRU algorithm
};

// Memory
int mem[2 << 16];

int initialize(char const *argv[]);

void processLoad(int address, int size);
void processStore(int address, int size, int data);
way* getFrame(int set, int way);

way* cache;

int main(int argc, char const *argv[]) {
	
	if (initialize(argv) == 1) return 1;
	
	char lineBuffer[LINE_MAX_STRING_SIZE] = "";
	char commandBuffer[COMMAND_MAX_STRING_SIZE] = "";
	int currentAddress = 0;
	int currentSize = 0;
	int currentData = 0;	

	while(fgets(lineBuffer, LINE_MAX_STRING_SIZE, file) != NULL) {

		// Check command
		sscanf(lineBuffer, "%4s",  commandBuffer);

		if(strcmp(commandBuffer, "load") == 0) {
			if(DEBUG) printf("\n%s", lineBuffer);
			sscanf(lineBuffer, "%s %x %d", commandBuffer, &currentAddress, &currentSize);

			processLoad(currentAddress, currentSize);
		} else {
			if(DEBUG) printf("\n%s", lineBuffer);
			sscanf(lineBuffer, "%s %x %d %x", commandBuffer, &currentAddress, &currentSize, &currentData);

			processStore(currentAddress, currentSize, currentData);
		}
	}

	free(cache);

	return 0;
}

int initialize(char const *argv[]) {

	file = fopen(argv[1], "r");

	if (file == NULL) {
		printf("Error reading file at address %s\n", argv[1]);
		return 1;
	}

	cacheSize = atoi(argv[2]);
	nWays = atoi(argv[3]);

	if (strcmp(argv[4], "wb") == 0) {
		storeAlg += WRITE_BACK;
		storeAlg += WRITE_ALLOCATE;
	}

	if (strcmp(argv[4], "wt") == 0) {
		storeAlg += WRITE_THROUGH;
		storeAlg += WRITE_NON_ALLOCATE;
	}

	blockSize = atoi(argv[5]);

	nSets = ((cacheSize << 10) / blockSize) / nWays;

	if(DEBUG) {
		printf("cachesize: %d, nWays: %d, storeAlg: %d, blocksize: %d\n", cacheSize, nWays, storeAlg, blockSize);
		printf("nSets: %d\n\n", nSets);
	}

	// Initialize cache to all unvalid data;

	cache = (way*)malloc((nSets * nWays) * sizeof(way));

	for(int i = 0; i < nSets; i++) {
		for(int j = 0; j < nWays; j++) {
			getFrame(i, j)->valid = 0;
		}
	}

	return 0;
}

way* getFrame(int set, int way) {
	return (&cache[set * nWays + way]);
}

void processLoad(int address, int size) {
	if(DEBUG) printf("Processing load. address: %x, size: %d\n", address, size);
}

void processStore(int address, int size, int data) {
	if(DEBUG) printf("Processing store. address: %x, size: %d, data: %x\n", address, size, data);
}