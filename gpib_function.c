#include "math.h"
#include "string.h"
#include "mex.h"
#include <gpib/ib.h>
#include "dispatch.h"

/*  Matlab:linux-GPIB Bridge (c) 2010 Richard George, University of Oxford
 *
 *  Compile by typing the following from the Matlab console:
 *
 *  mex gpib_function.c dispatch.c -lgpib
 */

extern DispatchTableEntry dispatch_table[];

int verbose = 2;
int write_verbose = 0;

int timeout_for_double(const double *t);

int ibfind_handler(int,mxArray*[],int,const mxArray*[]);
int ibsta_handler(int,mxArray*[],int,const mxArray*[]);
int ibcntl_handler(int,mxArray*[],int,const mxArray*[]);
int about_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int quiet_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int verbose_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int ibrdl_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int ibrd_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int ibwrt_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int ibclr_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int ibrsp_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int ibeos_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int ibeot_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);
int ibtmo_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[]);

char *about_desc    = "Matlab to linux-GPIB Bridge (c) 2010 Richard George, University of Oxford\n";
char *ibfind_desc   = "[handle]=ibfind('device_name') looks up a device in the /etc/gpib.conf file, and returns a handle to this device\n";
char *ibwrt_desc    = "[status,written_count]=ibwrt(handle,buffer) writes to GPIB-handle, from buffer, using length of string\n";
char *ibrdl_desc    = "[data,status,read_count]=ibrdl(handle) returns up to length bytes from the specified device\n";
char *ibrd_desc     = "[data,status,read_count]=ibrd(handle,length) returns up to 8192 bytes from the specified device\n";
char *ibclr_desc    = "ibclr(handle) performs a device clear on the specified device\n";
char *ibeos_desc    = "ibeos(handle,end_of_string)\n";
char *ibeot_desc    = "iteot(handle,value)\n";
char *ibtmo_desc    = "ibtmo(handle,timeout) Set the read time-out, in seconds. The resolution of timeout is log-spaced, e.g. 100ms,300ms,1s,3s,10s,30s ...\n";
char *ibsta_desc    = "return the value of ibsta\n";
char *ibcntl_desc   = "return the value of ibcntl\n";
char *ibrsp_desc    = "[result]=ibrsp(handle) performs a serial poll on the specified device\n";
char *quiet_desc    = "turn off debug output from other functions in this library\n";
char *verbose_desc    = "turn on debug output from other functions in this library\n";

DispatchTableEntry dispatch_table[] = { 
    /*
     * Add entries here: 
     * 
     * Matlab name      :   # LHS args  :   # RHS args  :   C function      :  Help text */
    {   "about"         ,   0           ,   0           ,   about_handler   ,  &about_desc},    
    {   "ibfind"        ,   1           ,   1           ,   ibfind_handler  ,  &ibfind_desc},
    {   "ibrdl"         ,   3           ,   2           ,   ibrdl_handler   ,  &ibrdl_desc},
    {   "ibrd"          ,   3           ,   1           ,   ibrd_handler    ,  &ibrd_desc},
    {   "ibsta"         ,   1           ,   0           ,   ibsta_handler   ,  &ibsta_desc},
    {   "ibcntl"        ,   1           ,   0           ,   ibcntl_handler  ,  &ibcntl_desc},
    {   "ibwrt"         ,   2           ,   2           ,   ibwrt_handler   ,  &ibwrt_desc},
    {   "ibclr"         ,   1           ,   1           ,   ibclr_handler   ,  &ibclr_desc},
    {   "ibrsp"         ,   1           ,   1           ,   ibrsp_handler   ,  &ibrsp_desc},
    {   "ibeos"         ,   1           ,   2           ,   ibeos_handler   ,  &ibeos_desc},
    {   "ibeot"         ,   1           ,   2           ,   ibeot_handler   ,  &ibeot_desc},
    {   "ibtmo"         ,   1           ,   2           ,   ibtmo_handler   ,  &ibtmo_desc},
    {   "quiet"         ,   0           ,   0           ,   quiet_handler   ,  &quiet_desc},
    {   "verbose"       ,   0           ,   0           ,   verbose_handler ,  &verbose_desc},
    /* Sentinel */
    {0,0,0,0,0} 
};

int timeout_for_double(const double *t)
{
    const double valid_timeouts[] = {0.0,10e-6,30e-6,100e-6,300e-6,1e-3,3e-3,10e-3,30e-3,100e-3,300e-3,1.0,3.0,10.0,30.0,100.0,300.0,1000.0};
    
    if (*t<=0.0) return 0;
    if (*t>=1000.0) return 17;
    
    int i=0;
    
    while ((valid_timeouts[i]<*t)) i++;
    
    return i;
}

int ibeot_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
{
    if (nrhs==2)
    {
        int iresult = -1;
        double *handle = mxGetPr(prhs[0]);
        double *eot = mxGetPr(prhs[0]);
        
        iresult = ibeot((int)*handle,(int)eot);
        
        if (nlhs==1)
        {
            plhs[0]=mxCreateDoubleScalar((double)iresult);
        }
        return 0;
        
    }
    
    return -1;
}

int ibeos_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
{
    if (nrhs==2)
    {
        int iresult = -1;
        double *handle = mxGetPr(prhs[0]);
        double *eos = mxGetPr(prhs[0]);
        
        iresult = ibtmo((int)*handle,(int)eos);
        
        if (nlhs==1)
        {
            plhs[0]=mxCreateDoubleScalar((double)iresult);
        }
        return 0;
        
    }
    
    return -1;
}

int ibtmo_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
{
    
    if (nrhs==2)
    {
        int iresult = -1;
        double *handle = mxGetPr(prhs[0]);
        double *timeout = mxGetPr(prhs[1]);
        int tmo=timeout_for_double(timeout);
        if (verbose>3) mexPrintf("Handle = %d, Timeout %g sec => %d\n",(int)*handle,*timeout,tmo); 
        
        iresult = ibtmo((int)*handle,tmo);
        
        if (nlhs==1)
        {
            plhs[0]=mxCreateDoubleScalar((double)iresult);
        }
        return 0;
        
    }
    
    return -1;
}

int ibfind_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
{
    const char *device = mxArrayToString(prhs[0]);
    if (verbose>2) mexPrintf("ibfind('%s')\n",device);
    int result = ibfind(device);
    if (verbose>2) mexPrintf("returns %d\n",result);
    plhs[0] = mxCreateDoubleScalar((double)result);
    return 0;
}

int ibsta_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
{
    if (nrhs==1)
    {
        plhs[0] = mxCreateDoubleScalar((double)ibsta);
    }
    
    return 0;
}

int ibcntl_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
{
    if (nrhs==1)
    {
        plhs[0] = mxCreateDoubleScalar((double)ibcntl);
    }
    
    return 0;
}

int ibwrt_handler(int nlhs, mxArray*plhs[], int nrhs, const mxArray* prhs[]) {
    if (nrhs==2) {
        double *handle = mxGetPr(prhs[0]);
        
        mwSize n=mxGetN(prhs[1]), m=mxGetM(prhs[1]);
        mxChar *buffer=mxGetChars(prhs[1]);
        
        char *message = 0;
        int i;
        
        message = calloc(n*m+2, sizeof(char));
        
        if (message!=0) {
            for (i=0;i<n*m;i++)
            {
                message[i]=(char)buffer[i];
                if (write_verbose>0) mexPrintf("message[%d]=0x%02X",i,(int)((unsigned char)message[i]));
                if ((write_verbose>0) & (message[i]>32) & (message[i]<126)) mexPrintf(" (%c)",message[i]);
                if (write_verbose>0) mexPrintf("\n");
            }
            message[i]=0;
            if (write_verbose>0) mexPrintf("calling ibwrt(handle=%d,message,length=%d)\n",(int)*handle,(int)n*m);
            
            int result = ibwrt((int)*handle, message, n*m);
                    
            if (write_verbose>0) mexPrintf("ibwrt returns 0x%04X, ibcntl=%d\n",result,ibcntl);
            
            free(message);
            
            if (nlhs>=1) plhs[0] = mxCreateDoubleScalar((double)result);
            if (nlhs>=2) plhs[1] = mxCreateDoubleScalar((double)ibcntl);
        }
        
    }
    
    return 0;
}

int ibrdl_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
{
    if (nrhs==2)
    {
        int i;
        double *handle = mxGetPr(prhs[0]);
        double *length = mxGetPr(prhs[1]);
        
        if (nlhs==3)
        {
            mwSize lengths[2];
            /* mexPrintf("sizeof(mxChar)=%d, sizeof(char)=%d\n",sizeof(mxChar),sizeof(char)); */
            
            char *buffer=calloc(((int)*length)+2,sizeof(char));
            int result = ibrd((int)*handle,(void *)buffer,(int)*length);
                        
            /* mexPrintf("result = %d, buffer = %s\n",result,buffer); */
            
            lengths[0]=1;
            lengths[1]=(mwSize)(ibcntl);
            plhs[0]=mxCreateCharArray(2,lengths);
            mxChar *mxCharBuffer=(mxChar *)mxGetPr(plhs[0]);  
            for (i=0;i<ibcntl;i++) mxCharBuffer[i]=(mxChar)buffer[i];

            free(buffer);

            if (nlhs>=1) plhs[1]=mxCreateDoubleScalar((double)result);
            if (nlhs>=2) plhs[2]=mxCreateDoubleScalar((double)ibcntl);            
        }
        
    }

    return 0;
}

int ibrd_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
{
    int i;
    char *buffer;
    
    if (nrhs==1)
    {
        double *handle = mxGetPr(prhs[0]);
              
        if (nlhs==3)
        {
            mwSize lengths[2];
            /* mexPrintf("sizeof(mxChar)=%d, sizeof(char)=%d\n",sizeof(mxChar),sizeof(char)); */

            char *buffer=calloc(8193,sizeof(char));
            int result = ibrd((int)*handle,(void *)buffer,8192);
                        
            /* mexPrintf("result = %d, buffer = %s\n",result,buffer); */
            
            lengths[0]=1;
            lengths[1]=(mwSize)(ibcntl);
            plhs[0]=mxCreateCharArray(2,lengths);
            mxChar *mxCharBuffer=(mxChar *)mxGetPr(plhs[0]);  
            for (i=0;i<ibcntl;i++) mxCharBuffer[i]=(mxChar)buffer[i];

            free(buffer);

            if (nlhs>=1) plhs[1]=mxCreateDoubleScalar((double)result);
            if (nlhs>=2) plhs[2]=mxCreateDoubleScalar((double)ibcntl);

        }
        
    }
    
    return 0;
}

int ibclr_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
 {
    int result = -1;
    
    if (nrhs==1) {
        double *handle = mxGetPr(prhs[0]);
        result = ibclr((int)*handle);
        
        if (nlhs==1) {
            plhs[0]=mxCreateDoubleScalar((double)result);
        }
    }

    return 0;
}

int ibrsp_handler(int nlhs,mxArray*plhs[],int nrhs,const mxArray* prhs[])
{
    if (nrhs==1)
    {
        double *handle = mxGetPr(prhs[0]);
        char result = 0;
        
        ibrsp((int)*handle,&result);
        
        if (nlhs==1)
        {
            plhs[0]=mxCreateDoubleScalar((double)result);
        }
        
    }
    
    return 0;
}

int quiet_handler(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    verbose = 0;
    return 0;
}

int verbose_handler(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    verbose = 1;
    mexPrintf("gpib_function: debug output is now enabled. Call gpib_function('quiet') to disable.\n");
    return 0;
}
    
/* Example handler */
int about_handler(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    mexPrintf("Matlab to Linux-GPIB interface, (c) 2010 Richard George, University of Oxford\n\n");
    return 0;
}

void ExitFcn()
{
    mexPrintf("Exit function called for gpib_function()\n");
}
