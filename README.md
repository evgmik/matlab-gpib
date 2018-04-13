# A binding for Matlab to Linux-GPIB

This original files were found at
http://code.google.com/p/matlab-gpib/

and  cloned with the following command
~~~
hg clone https://code.google.com/p/matlab-gpib/
~~~

This code is distributed under GNU GPL v2 license


## INSTALLATION.

In Matlab switch to this directory and run

~~~
mex gpib_function.c dispatch.c -lgpib
~~~

Above will compile the proper Matlab interface,
which apparently should happen by itself at the first execution of 'lgpib'
within Matlab.

If you want to run it from network drive move resulting 'gpib_function.mexglx'
to a computer dependent location.


See 'gpib_test.m' and 'HP8596E_take_data.m' for usage examples.

