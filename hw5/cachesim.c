#include<stdio.h>
#include<stdlib.h>
#include<cstring>

#define DEBUG 0

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
int tagSize; // amount of bits for tag used in each way
int indexSize; // corresponds to the n-th set in the cache
int offsetSize; // offset of data within a block

// Reading parameters
FILE* file;
#define COMMAND_MAX_STRING_SIZE 10
#define ADDRESS_MAX_STRING_SIZE 5
#define SIZE_MAX_STRING_SIZE 3
#define DATA_MAX_SIZE 129
#define LINE_MAX_STRING_SIZE 142

// Way structure
#define BLOCK_MAX_SIZE 64

typedef struct way way;
struct way {
	int valid;
	int tag;
	char data[BLOCK_MAX_SIZE];
	int LRUT; // used for LRU algorithm
};

// Memory
char mem[2 << 16];

int initialize(char const *argv[]);

void processLoad(int address, int size);
void processStore(int address, int size, char* data);

way* getFrame(int set, int way);
way* getSet(int set);
int computeIndex(int address);
int computeOffset(int address);
int computeTag(int address);

void updateLRUT(int index, int ignoreTag);
void bringBlockToCache(int address);
void printData(int size, char* data);
void printLoadResult(char* data, int address, int size, int isHit);

way* cache;

int main(int argc, char const *argv[]) {
	
	if (initialize(argv) == 1) return 1;
	
	char lineBuffer[LINE_MAX_STRING_SIZE] = "";
	char commandBuffer[COMMAND_MAX_STRING_SIZE] = "";
	int currentAddress = 0;
	int currentSize = 0;
	char currentData[DATA_MAX_SIZE] = "";	

	while(fgets(lineBuffer, LINE_MAX_STRING_SIZE, file) != NULL) {

		// Check command
		sscanf(lineBuffer, "%4s",  commandBuffer);

		if(strcmp(commandBuffer, "load") == 0) {
			if(DEBUG) printf("\n%s", lineBuffer);
			sscanf(lineBuffer, "%s %x %d", commandBuffer, &currentAddress, &currentSize);

			processLoad(currentAddress, currentSize);
		} else {
			if(DEBUG) printf("\n%s", lineBuffer);

			char* data = strrchr(lineBuffer, ' ') + 1; // data field points to first character of what comes after the last space

			int i = 0;
			while ((*(data + 2*i + 1) != '\0') & *(data + 2*i + 1) != '\n') {

				sscanf(data + 2*i, "%2hhx", currentData + i);
				i += 1;
			}

			sscanf(lineBuffer, "%s %x %d %*d", commandBuffer, &currentAddress, &currentSize);
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

	offsetSize = ffs(blockSize) - 1; // offset = log2(blocksize)
	indexSize = ffs(nSets) - 1; // index = log2(nSets)
	tagSize = 16 - offsetSize - indexSize;

	if(DEBUG) {
		printf("cachesize: %dKB, nWays: %d, storeAlg: %d, blocksize: %dB\n", cacheSize, nWays, storeAlg, blockSize);
		printf("nSets: %d\n", nSets);
		printf("offset: %d bits, index: %d bits, tag: %d bits", offsetSize, indexSize, tagSize);
		printf("\n");
	}

	// Initialize cache to all unvalid data;

	cache = (way*)calloc((nSets * nWays), sizeof(way));

	//for(int i = 0; i < nSets; i++) {
	//	for(int j = 0; j < nWays; j++) {
	//		getFrame(i, j)->valid = 0;
	//	}
	//}

	return 0;
}

way* getFrame(int set, int way) {
	return (&cache[set * nWays + way]);
}

// Returns pointer to first way in a set
// Array is still only bounded by the number of sets,
// meaning that if you iterate through the ways a wrong number of times,
// you might end up ending in a different set;
way* getSet(int set) {
	return (&cache[set * nWays]);
}

int computeIndex(int address) {
	int indexMask = (((0xFFFFFFFF >> offsetSize) << offsetSize) << (tagSize + (sizeof(int) * __CHAR_BIT__) - 16)) >> (tagSize + (sizeof(int) * __CHAR_BIT__) - 16);
	int index = (address & indexMask) >> offsetSize;

	if (DEBUG) printf("Mask is %x; index result is %d\n", indexMask, index);

	return index;
}

int computeOffset(int address) {
	int offMask = 0xFFFF >> (16 - offsetSize);
	int offset = address & offMask;

	if (DEBUG) printf("Mask is %x; offset result is %d\n", offMask, offset);
	return offset;
}

int computeTag(int address) {
	int tagMask = (0xFFFF >> (offsetSize + indexSize)) << (offsetSize + indexSize);
	int tag = (address & tagMask) >> (offsetSize + indexSize);

	if (DEBUG) printf("Mask is %x; tag result is %d\n", tagMask, tag);

	return tag;
}

void processLoad(int address, int size) {
	if (DEBUG) printf("\nprocessLoad: Processing load. address: %x, size: %d\n", address, size);

	//// First check if we can get a hit in the cache
	// Compute address offset, index and tag using bit masks

	int offset = computeOffset(address);
	int index = computeIndex(address);
	int tag = computeTag(address);

	// Check all ways in a set and check validity and tag
	way* way = getSet(index);
	int hit = 0;

	if (DEBUG) printf("Checking set #%d for hit\n", index);
	for(int i = 0; i < nWays; i++) {
		if((way->valid != 0) && way->tag == tag) {
			if (DEBUG) printf("hit!\n");
			hit = 1;

			printLoadResult(way->data + offset, address, size, hit); // TODO implement
			way->LRUT = 0;
			break;
		} else {
			if (DEBUG) printf("miss at way %d, iterating...\n", i);
			way++; // TODO Check if this works
		}
	}

	if(hit == 0) {
		if (DEBUG) printf("Missed all ways. Reading from memory\nResult: ");

		char data[size];

		for(int i = 0; i < size; i++) {
			data[i] = mem[address + i];
			if (DEBUG) printf("%02hhx", data[i]);
		}
		if (DEBUG) printf("\n");

		printLoadResult(data, address, size, 0);
		bringBlockToCache(address);
	}

	updateLRUT(index, tag);
}

// Increases the LRUT in the given set but ignores a way with a given tag
// Doing this allows us to count how many times it's been since a given way in the cache was last accessed,
// so the one with the biggest LRUT is the least recently used. 
void updateLRUT(int index, int ignoreTag) {
	if (DEBUG) printf("\nupdateLRUT: Updating set %d LRUT, ignoring tag %d\n", index, ignoreTag);

	way* way = getSet(index);

	for (int i = 0; i < nWays; i++) {
		if (way->tag != ignoreTag) {
			(way->LRUT)++;
		}

		way++; // TODO Check if this works
	}
}

void bringBlockToCache(int address) {
	if (DEBUG) printf("\nbringBlockToCache: Bringing block to cache\n");

	// Clean offset bits
	address = (address >> offsetSize) << offsetSize;

	char data[DATA_MAX_SIZE];

	if (DEBUG) printf("Block read: ");
	// Find the start of the block and make the data array
	for (int i = 0; i < blockSize; i++) {
		data[i] = mem[address + i];
		if (DEBUG) printf("%02hhx", data[i]);
	}
	if (DEBUG) printf("\n");

	// Find the way with the greatest LRUT, meaning it was the least recently used.
	way* currentWay = getSet(computeIndex(address));
	way* targetWay = currentWay;
	int foundWay = 0;
	int nWay = 0;

	if(DEBUG) printf("LRUTs:");
	for (int i = 0; i < nWays; i++) {		
		if (DEBUG) printf("%d ", currentWay->LRUT);

		// If we find an invalid way, then we write it there
		if(currentWay->valid == 0) {
			if (DEBUG) printf("\nFound invalid way%d", nWay);
			targetWay = currentWay;
			foundWay = nWay;
			break;
		}

		if(targetWay->LRUT < currentWay->LRUT) {
			targetWay = currentWay;
			foundWay = nWay;
		}

		currentWay++; // TODO Check if this works
		nWay++;
	}
	if (DEBUG) printf("\n");

	// Replace the data in the way with the current being loaded
	if(DEBUG) printf("Writing to way%d\n", foundWay);
	memcpy(targetWay->data, data, BLOCK_MAX_SIZE);
	targetWay->LRUT = 0;
	targetWay->tag = computeTag(address);
	targetWay->valid = 1;
}

void processStore(int address, int size, char* data) {
	if(DEBUG) {
		printf("Processing store. address: %x, size: %d, data: ", address, size);
		printData(size, data);
		printf("\n");
	}

	memcpy(mem + address, data, size);
}

void printLoadResult(char* data, int address, int size, int isHit) {
	char hitOrMiss[5];

	if(isHit) {
		strcpy(hitOrMiss, "hit");
	} else {
		strcpy(hitOrMiss, "miss");
	}

	printf("load %04x %s ", address, hitOrMiss);
	printData(size, data);
	printf("\n");
	
}

void printData(int size, char* data) {
	for(int i = 0; i < size; i++) {
		printf("%02hhx", *(data + i));
	}
}