#include "math.h"
#include "mex.h"
#define DISPATCH_C
#include "dispatch.h"


/*  Matlab Bridge (c) 2010 Richard George, University of Oxford
 *
 *  Compile by typing the following from the Matlab console:
 *
 *  mex [other_module.c] dispatch.c 
 */

int counter = 0;
 
extern DispatchTableEntry dispatch_table[];


char *help_help="List the available functions\n";

int runDispatchTable(DispatchTableEntry functions[], const char *request, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

int help_nonspecific_handler(int nlhs, mxArray*plhs[], int nrhs, const mxArray* prhs[]);
int help_specific_handler(int nlhs, mxArray*plhs[], int nrhs, const mxArray* prhs[]);

/* Example dispatch table - define a function called 'help' that can print the contents of the dispatch table */

DispatchTableEntry internal_dispatch_table[] = {
    {   "help"         ,   0           ,   0           ,   help_nonspecific_handler,  &help_help},
    {   "help"         ,   0           ,   1           ,   help_specific_handler,  0 },
    /* Sentinel */
    {   0, 0, 0, 0, 0}
};

int help_nonspecific_handler(int nlhs, mxArray*plhs[], int nrhs, const mxArray* prhs[]) {
    displayValidFunctions(dispatch_table);
}

int help_specific_handler(int nlhs, mxArray*plhs[], int nrhs, const mxArray* prhs[]) {
    if (nrhs==1) {
        const char *request = mxArrayToString(prhs[0]);
        mexPrintf("help for %s:\n\n", request);
        int i;
        for (i=0;dispatch_table[i].function_name!=0;i++) {
            if (strcmp(request, dispatch_table[i].function_name)==0) {
                if ((*(dispatch_table[i].help))!=0) mexPrintf("%s\n", *(dispatch_table[i].help));
            }
        }
    }
    return 0;
}

/* This code searches the dispatch table, looking for a match and checking the number of arguments passed */

int runDispatchTable(DispatchTableEntry functions[], const char *request, int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int result;
    int i;
    int k=0;
    
    int flag_rhs_error=0;
    int flag_lhs_error=0;
    
    for (i=0;functions[i].function_name!=0;i++) {
        /* mexPrintf("runDispatchTable: Comparing %s %s\n", functions[i].function_name, request); */
        if (strcmp(request, functions[i].function_name)==0) {
            if (nlhs==functions[i].nlhs) {
                
                if ((nrhs-1)==functions[i].nrhs) {
                    result = functions[i].handler(nlhs, &plhs[0], nrhs-1, &prhs[1]);
                    return 1;
                }
                else {
                    flag_rhs_error=1;
                    k=i;
                }
                
            }
            else {
                flag_lhs_error=1;
                k=i;
            }
        }
    }
    
    if (flag_rhs_error) mexPrintf("Expecting %d parameter(s) on the right of function %s, but found %d\n", functions[k].nrhs,request, nrhs-1);
    if (flag_lhs_error) mexPrintf("Expecting %d parameter(s) on the left of function %s, but found %d\n", functions[k].nlhs,request, nlhs);
    
    if ((flag_lhs_error==1) || (flag_rhs_error==1)) return -2;
    return -1;
}

/* This function prints the functions defined in a dispatch table passed in as the argument */

void displayValidFunctions(DispatchTableEntry functions[]) {
    mexPrintf("Available functions are:\n\n");
    int i,j;
    char c;
    
    for (i=0;functions[i].function_name!=0;i++) {
        c='A';
        mexPrintf("function ");
        
        if (functions[i].nlhs>0) {
            mexPrintf("[");
            for (j=0;j<functions[i].nlhs;j++) {
                if (j>0) mexPrintf(",");
                mexPrintf("%c",c++);
            }
            mexPrintf("]=");
        }
        
        mexPrintf("%s(",functions[i].function_name);
        
        if (functions[i].nrhs>0) {
            for (j=0;j<functions[i].nlhs;j++) {
                if (j>0) mexPrintf(",");
                mexPrintf("%c",c++);
            }
        }
        mexPrintf(")\n");
        if (functions[i].help!=0) {
            mexPrintf("\n%s\n\n",*functions[i].help);
        }
    }
}

/* The entry point from MATLAB
 * 
 * The first argument from Matlab prhs[0] is used to look-up a value in the dispatch table. If a match is found, the handler function is called with the remaining arguments 
 */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    /* Setup on first run */
    if (counter==0)
    {
        mexPrintf("adding exit hook for gpib_function()\n");
        mexAtExit(ExitFcn);
    }
 
    /* Decode the requested feature */
    if (nrhs>=1) {
        const char *request = mxArrayToString(prhs[0]);
        int found;
        
        found=runDispatchTable(internal_dispatch_table, request, nlhs, plhs, nrhs, prhs);
        
        if (found<0) {
            found=runDispatchTable(dispatch_table, request, nlhs, plhs, nrhs, prhs);
        }
    }
    else {
        /* Display a help message */
        displayValidFunctions(dispatch_table);
    }
    
    counter++;
    return;
}

