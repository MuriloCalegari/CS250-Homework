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
int currentSize = LIST_INITAL_SIZE;
int personCount = 0;

void ensureListCapacity();
void putTransmitter(char* transmitterName, char* infectedName);
void log(char* message, ...);

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
        if(strcmp(line, "DONE\n") == 0) break;
        sscanf(line, "%s %s", infected, transmitter);

        printf("Inserting %s->%s into list\n", transmitter, infected);

        putTransmitter(transmitter, infected);
    }

    for(int i = 0; i < personCount; i++) {
        printf("%s %s %s\n", list[i].name, list[i].infected[0].name, list[i].infected[1].name);
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
    if(personCount + 1 > currentSize) {
        int newArraySize = 2 * currentSize * sizeof(person);

        person* newList = (person*)malloc(newArraySize);
        
        memcpy(newList, list, personCount * sizeof(person));

        person* trash = list;
        list = newList;

        free(trash);

        currentSize = newArraySize;
    }
}

/*
    Records in the list array a new infected person,
    creating the transmitter entry if it is not found in the array.

    The function keep the list sortered by putting new transmitters
    right in the position they should be and shifting the remaining elements
    to the right
*/
void putTransmitter(char* transmitterName, char* infectedName) {

    person* infected = (person*)malloc(sizeof(person));
    infected->infected = (person*)malloc(sizeof(2 * sizeof(person)));
    strcpy(infected->name, infectedName);

    if(personCount == 0) {        
        person* transmitter = (person*) malloc(sizeof(person));
        transmitter->infected = (person*)malloc(sizeof(2 * sizeof(person)));

        strcpy(transmitter->name, transmitterName);

        transmitter->infected[0] = *infected;

        list = (person*)malloc(LIST_INITAL_SIZE * sizeof(person));
        list[0] = *transmitter;

        personCount++;

        log("%s is the first person inserted in the list.", list[0].name);

        return;
    }

    for(int i = 0; i < personCount; i++) {
        person currentPerson = list[i]; /* pointer or array? */

        int strCmp = strcmp(currentPerson.name, transmitterName);

        if(strCmp == 0) {
            if(&currentPerson.infected[0] == NULL) {
                currentPerson.infected[0] = *infected;
            } else {
                if(strcmp(currentPerson.infected[0].name, transmitterName)) {
                    currentPerson.infected[1] = *infected;
                } else {
                    currentPerson.infected[1] = currentPerson.infected[0];
                    currentPerson.infected[0] = *infected;
                }
            }
        } else if(strCmp < 0) {
            if(i != personCount - 1) continue;

            person* transmitter = (person*)malloc(sizeof(person));
            transmitter->infected = (person*)malloc(sizeof(2 * sizeof(person)));
            transmitter->infected[0] = *infected;

            strcpy(transmitter->name, transmitterName);

            ensureListCapacity();
            list[i + 1] = *transmitter;

            personCount++;
            break;
        } else {
            ensureListCapacity();
            memmove(&list[i+1], &list[i], (int) (personCount - i) * sizeof(person));

            person* transmitter = (person*)malloc(sizeof(person));
            transmitter->infected = (person*)malloc(sizeof(2 * sizeof(person)));
            transmitter->infected[0] = *infected;

            strcpy(transmitter->name, transmitterName);

            list[i] = *transmitter;

            personCount++;
            break;
        }
    }
}