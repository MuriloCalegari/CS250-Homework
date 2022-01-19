#include<stdio.h>
#include<stdlib.h>

int computefn(int n);

int main(int argc, char const* argv[]) {
    int n = atoi(argv[1]);

    printf("%d", computefn(n));

    return 0;
}

int computefn (int n) {
    if(n == 0) return -2;

    return 3 * n + 2 * computefn(n - 1) - 2;
}