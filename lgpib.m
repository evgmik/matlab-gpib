classdef lgpib
    
    properties
        handle
    end
    
    methods
        
        function [obj] = lgpib(name)
            
            if exist('gpib_function')~=3
                lgpib.Compile();
            end
            
            obj.handle = gpib_function('ibfind',name);
            
            if (obj.handle<0)
                fprintf('lgpib Error: Could not open device ''%s''\n',name);
            end
            
        end
        
        function [status,write_count] = write(obj,message)          
     
            [gpib_status,gpib_count] = gpib_function('ibwrt',obj.handle,message);
            
            if nargout>=1
                status = gpib_status;
            end
            
            if nargout>=2
                write_count=gpib_count;
            end      
        end
        
        function [reply,status,read_count] = read(obj,l)  
            
            if nargin==1
                l=8192;
            end
            
            [gpib_reply,gpib_status,gpib_count] = gpib_function('ibrdl',obj.handle,l);
            
            reply = gpib_reply;
                        
            if nargout>=2
                status = gpib_status;
            end
            
            if nargout>=3
                write_count=gpib_count;
            end
        end
        
        function [reply] = query(obj,message,l)
            if nargin==2
                l = 8192;
            end
            
            obj.write(message);
            
            reply = obj.read(l);
        end
        
        function [reply] = set_timeout(obj,tmo)
            reply = gpib_function('ibtmo',obj.handle,tmo);
        end
                
        function [reply] = serial_poll(obj)
            reply = gpib_function('ibrsp',obj.handle);
        end
        
        function [status] = get_status(obj)
            status = gpib_function('ibsta',obj.handle);
        end
        
        function [cntl] = get_counter(obj)
            status = gpib_function('ibcntl',obj.handle);
        end
        
        function [status] = clear(obj)
            status = gpib_function('ibclr',obj.handle);
        end
        
        function [status] = interface_clear(obj)
            status = obj.clear();
        end
        
    end      
    
    methods (Static)
        function Compile
            fprintf('Compiling gpib_function.c\n');
            mex gpib_function.c dispatch.c -lgpib
        end
    end
    
end
        