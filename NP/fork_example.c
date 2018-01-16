#include <unistd.h>
#include <stdio.h>
int main (){
    pid_t fpid;
    fpid=fork();
    if (fpid < 0)printf("error in fork!");
    else if (fpid == 0) {
        printf("I am child.Process id is %d\n",getpid());
    }
    else {
        printf("I am parent,Process id is %d\n",getpid());
    }
    return 0;
}
