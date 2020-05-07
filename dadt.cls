/* 
    Dynamic Attribute Data Type 
    lazy getters and setters 
    
    slightly improved from a version which was found on https://rosettacode.org/wiki/Add_a_variable_to_a_class_instance_at_runtime#Unknown_Method_Access
    
    when you perform a get or set, or use the = then it creates the methods 
    
    so 
    
    dog = .DynamicAttributeDataType~new("Fido") 
    dog~setpaws(4)
    say dog~paws  /* prints 4  */ 
    say dog~getpaws  /* also prints 4  */ 
    dog~paws= 3 /* poor fido */
    dog~noise = "bow wow" 
    say dog dog~getpaws() dog~getNoise /* now prints Fido 3 bow wow */

*/ 


::class DynamicAttributeDataType public MIXINCLASS String


::method init public 
    self~init:super()

    
/* 
the method = will test on the main string only, not attributes 
*/ 

::method "==" 
use arg obj
match = .true 

    if obj~instanceof(.DynamicAttributeDataType) = .false then do 
        match = .false 
    end  
    
    
    
    return match 





::method setAttributeDataType public 

-- the unknown method will get invoked any time an unknown method is
-- used.  This UNKNOWN method will add attribute methods for the given
-- name that will be available on all subsequent uses.
::method unknown
  use strict arg messageName, arguments

  
    set = .false
    select
        when messageName~left(3) = "SET" then do
            set = .true
            variableName = right(messageName, length(messageName)-3)
        end 
        when messageName~left(3) = "GET" then do /* a getter which hasn't been set... this is going to be a problem */ 
            set = .false
        end 
        when arguments~items = 0 then do /* no attributes requested so it must be a call for data, and it's undefined  */ 
                set = .false
        end
        when messageName~right(1) == '=' then do
            set = .true
            variableName = messageName~left(messageName~length - 1)
        end
        otherwise do 
            nop
        end 
    end 
    

  /* You've requested an undefined value so return nil */
  if set = .false then do 
    return nil 
  end 
  

  -- define a pair of methods to set and retrieve the instance variable.  These are
  -- created at the object scope
  self~setMethod(variableName, 'expose' variableName'; return' variableName)
  self~setMethod("get"||variableName, 'expose' variableName'; return' variableName)
  self~setMethod(variableName'=', 'expose' variableName'; use strict arg value;' variableName '= value' )
  self~setMethod("set"||variableName, 'expose' variableName'; use strict arg value;' variableName '= value' )
 
 
    -- reinvoke the original message.  This will now go to the dynamically added methods
    forward to(self) message(messageName) arguments(arguments)

 
 
 
