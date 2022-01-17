#include<stdio.h>
#include<stdlib.h>
#include <cstring>

#define NAME_MAX_SIZE 31
#define LINE_MAX_SIZE 62
#define LIST_INITAL_SIZE 1

typedef struct person person;

struct person {
    char name[31];
    person* infected;
};

person* list;
int personCount = 0;

void ensureListCapacity();
void putEntry(char* transmitterName, char* infectedName);

int main(int argc, char const* argv[]) {
    FILE* file = fopen("./covidtrackerstatsfile.txt", "r");
    char line[LINE_MAX_SIZE];

    if (file == NULL) {
        printf("Error reading file");
        return 1;
    }

    char infected[NAME_MAX_SIZE];
    char transmitter[NAME_MAX_SIZE];

    while (fgets(line, LINE_MAX_SIZE, file) != NULL) {
        sscanf(line, "%s %s", infected, transmitter);
        putEntry(transmitter, infected);
    }

    return 0;
}

/*
    Similar to the ArrayList implementation in Java,
    here I double the size of the person list[]
    every time I need to fit one more element and the current
    list size is not sufficient
*/
void ensureListCapacity() {
    int currentSize = sizeof(list) / sizeof(list);

    if(personCount + 1 > currentSize) {
        person* newList = (person*) malloc(2*currentSize*sizeof(person));
        
        memcpy(newList, list, (int) sizeof(list));

        person* trash = list;
        list = newList;

        free(trash);
    }
}

/*
    Records in the list array a new infected person,
    creating the transmitter entry if it is not found in the array.

    The function keep the list sortered by putting new transmitters
    right in the position they should be and shifting the remaining elements
    to the right
*/
void putEntry(char* transmitterName, char* infectedName) {

    if(personCount == 0) {
        list = (person*) malloc(LIST_INITAL_SIZE);
        
        person* transmitter = (person*) malloc(sizeof(person));
        person* infected = (person*) malloc(sizeof(person));
        transmitter->infected = (person*) malloc(sizeof(2));
        infected->infected = (person*)malloc(sizeof(2));

        strcpy(transmitter->name, transmitterName);
        strcpy(infected->name, infectedName);

        transmitter->infected[0] = *infected;

        list[0] = *transmitter;

        personCount++;

        return;
    }

    for(int i = 0; i < personCount; i++) {
        person currentPerson = list[i]; /* pointer or array? */

        int strCmp = strcmp(currentPerson.name, transmitterName);
    }

    ensureListCapacity();
}