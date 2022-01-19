#include<stdio.h>
#include<stdlib.h>

int main(int argc, char const* argv[]) {
    int n = atoi(argv[1]);

    int mersenne = 1;

    for (int i = 1; i <= n; i++) {
        mersenne = 2 * mersenne;
    }

    mersenne--;

    printf("%d", mersenne);

    return 0;
}