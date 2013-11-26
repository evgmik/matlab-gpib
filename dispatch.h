#ifndef DISPATCH_H
#define DISPATCH_H

typedef struct tagDispatchTableEntry {
    char *function_name;
    int nlhs;
    int nrhs;
    int (*handler)(int,mxArray *[],int,const mxArray *[]);
    char **help;
} DispatchTableEntry;

#ifndef DISPATCH_C
extern int counter;
extern char *help_help;
#endif

void displayValidFunctions();
void ExitFcn();
int help_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
       
#endif