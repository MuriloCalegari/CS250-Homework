#include<stdio.h>
#include<stdlib.h>
#include <cstring>

#define NAME_MAX_SIZE 31
#define LINE_MAX_SIZE 62

typedef struct person person;
typedef struct node node;

struct person {
    char name[NAME_MAX_SIZE];
    char infected[2][NAME_MAX_SIZE];
    person* next;
};

person* firstElement;

void putTransmitter(char* transmitterName, char* infectedName);
void putInfected(char* infectedName);

int main(int argc, char const* argv[]) {
    FILE* file = fopen(argv[1], "r");
    char line[LINE_MAX_SIZE];

    if (file == NULL) {
        printf("Error reading file");
        return 1;
    }

    char infected[NAME_MAX_SIZE];
    char transmitter[NAME_MAX_SIZE];

    while (fgets(line, LINE_MAX_SIZE, file) != NULL) {
        if (strcmp(line, "DONE\n") == 0) break;
        sscanf(line, "%s %s", infected, transmitter);

        putTransmitter(transmitter, infected);
        putInfected(infected);
    }

    fclose(file);

    person* currentPerson = firstElement;

    while(currentPerson != NULL) {
        if (currentPerson->infected[1][0] != '\0') {
            printf("%s %s %s\n", currentPerson->name, currentPerson->infected[0], currentPerson->infected[1]);
        } else if (currentPerson->infected[0][0] != '\0') {
            printf("%s %s\n", currentPerson->name, currentPerson->infected[0]);
        } else {
            printf("%s\n", currentPerson->name);
        }

        person* trash = currentPerson;        
        currentPerson = currentPerson->next;
        free(trash);
    }

    return 0;
}

/*
    Uses a linked list to store all infecters.
    The list is maintained sorted by inserting new elements
    right in the position where they should be, using a relinking of the preceeding node
    to the new element and this to the previous succedding node.
*/
void putTransmitter(char* transmitterName, char* infectedName) {

    if (firstElement == NULL) {

        person* transmitter = (person*)malloc(sizeof(person));
        strcpy(transmitter->name, transmitterName);
        strcpy(transmitter->infected[0], infectedName);
        transmitter->next = NULL;

        firstElement = transmitter;

        return;
    }

    person* currentPerson = firstElement;

    while (currentPerson != NULL) {
        int strCmp = strcmp(currentPerson->name, transmitterName);

        /*
            If we find the element, we just insert the infected person
            and break the loop because we are done
        */

        if (strCmp == 0) {
            if (currentPerson->infected[0][0] == '\0') {
                strcpy(currentPerson->infected[0], infectedName);
            } else {
                if (strcmp(currentPerson->infected[0], infectedName) < 0) {
                    strcpy(currentPerson->infected[1], infectedName);;
                } else {
                    strcpy(currentPerson->infected[1], currentPerson->infected[0]);
                    strcpy(currentPerson->infected[0], infectedName);;
                }
            }

            break;
        }

        person* transmitter = (person*)malloc(sizeof(person));
        strcpy(transmitter->name, transmitterName);
        strcpy(transmitter->infected[0], infectedName);
        transmitter->next = NULL;
        
        if (strCmp < 0) {
            if (currentPerson->next == NULL) {
                currentPerson->next = transmitter;
                break;
            }
            
            if (strcmp(currentPerson->next->name, transmitterName) > 0) {
                transmitter->next = currentPerson->next;
                currentPerson->next = transmitter;
                break;
            }
        } else {
            transmitter->next = currentPerson;
            firstElement = transmitter;
            break;
        }

        currentPerson = currentPerson->next;
    }
}

/*
    Same thing as putTransmitter, but inserting only the infected person as a patient
*/
void putInfected(char* infectedName) {

    if (firstElement == NULL) {

        person* transmitter = (person*)malloc(sizeof(person));
        strcpy(transmitter->name, infectedName);
        transmitter->next = NULL;

        firstElement = transmitter;

        return;
    }

    person* currentPerson = firstElement;

    while (currentPerson != NULL) {
        int strCmp = strcmp(currentPerson->name, infectedName);

        person* infected = (person*)malloc(sizeof(person));
        strcpy(infected->name, infectedName);
        infected->next = NULL;

        if (strCmp < 0) {
            if (currentPerson->next == NULL) {
                currentPerson->next = infected;
                break;
            } else if (strcmp(currentPerson->next->name, infectedName) > 0) {
                infected->next = currentPerson->next;
                currentPerson->next = infected;
                break;
            }
        } else {
            infected->next = currentPerson;
            firstElement = infected;
            break;
        }

        currentPerson = currentPerson->next;
    }
}